class MobBattlesController < ApplicationController

include ApplicationHelper

	def new
	end

	def index
		@battles = current_char.all_battles
	end

	def show
		@battle = MobBattle.find(params[:id])

			@defender = Character.find(@battle.defender_id)
			@challenger = Mob.find(@battle.challenger_id)

		@player1 = @defender
		@player2 = @challenger

	end

	def create

			@challenger = Character.find(current_char.id)
			@opponent = get_random_mob

			@challenger_id = @opponent.id
			@defender_id = @challenger.id

			if (@challenger.current_hp == 0) or (@opponent.current_hp == 0)
				redirect_to :root, notice: "Either your opponent or yourself is not ready to join a battle"
			elsif current_char.battle_session
				redirect_to :root, notice: "You already have a battle in session" 
			else
				new_battle = MobBattle.create(challenger_id: @challenger_id, defender_id: @defender_id, status: @defender_id )
				BattleSession.create(fight_id: new_battle.id, fight_type: "MobBattle", character_id: new_battle.defender_id)

				redirect_to mob_battle_path(new_battle.id)
			end
	end

		def attack

			if battle_session.fight.status == current_char.id.to_s
				@attack = Attack.find(params[:id])

				@target = Mob.find(params[:ch])

				@current = Character.find(current_char.id)

				@battle = MobBattle.find(battle_session.fight.id)

				@current.current_mp -= @attack.mp_consumption

	    	base_dmg = @attack.base_dmg
	    	dmg_range = @attack.dmg_range

	    	@critical = true if rand > 0.8
	    	@dmg = (base_dmg + rand(dmg_range))
	    	@dmg = (@dmg * 1.8).round if @critical

	    	@target.current_hp -= @dmg if @target.current_hp > 0

		    @target.current_hp = 0 if @target.current_hp < 0

	  	  @target.save
	  	  @current.save

	  	  FightTurn.create( maker_id: @current.id ,maker_type: "Character", target_id: @target.id, target_type: "Mob", 
		    									damage: @dmg, healed: nil, skill_used: @attack.name, skill_id: @attack.id, skill_type: "Attack", 
		    									item_used: nil,item_used_id: nil,item_used_type: nil, critical: @critical, fight_type: "MobBattle", fight_id: @battle.id )

	  	  change_battle_status(@battle)

	  	  mob_random_move

	    	redirect_to mob_battle_path(@battle.id, cr: @critical, p: @target.id, d: 1, dmg: @dmg, att: @attack)
	    elsif battle_session.fight.status == "ended"
	    	redirect_to :back, notice: "This battle has ended"
	    else
	    	redirect_to :back, notice: "It's not your turn yet" 
	    end
    end

    def change_battle_status(battle)
    	if Mob.find(battle.challenger_id).current_hp <= 0 || Character.find(battle.defender_id).current_hp <= 0 
    		battle.status = "ended"
    	elsif battle.status == "begin"
    		battle.status = battle.defender_id.to_s
    	elsif battle.status == battle.defender_id.to_s
    		battle.status = battle.challenger_id
    	else
    		battle.status = battle.defender_id
    	end

    	battle.save
    end

    def get_random_mob
    	@monster = Monster.find(rand(Monster.all.length)+1)

    	@level = 2
    	@total_hp = @monster.max_hp + (@monster.hp_per_level * (@level -1))
    	@total_mp = @monster.max_mp + (@monster.mp_per_level * (@level -1))

    	@held_gold = (@monster.base_gold + (@monster.gold_per_level * (@level -1))) * (1 + (rand() / 4))
    	@exp = @monster.base_exp + (@monster.exp_per_level * @level -1)
 

    	mob = Mob.create(
    			species_type: "Monster", species_id: @monster.id , 
    			level: @level, current_hp: @total_hp, current_mp: @total_mp, max_hp: @total_hp, max_mp: @total_mp,
    			held_gold: @held_gold
    			)
    end

    def mob_random_move

				@current = Mob.find(params[:ch])

				@target = Character.find(current_char.id)

				not_enough_mp = true
				selection_counter = 0

				while not_enough_mp && selection_counter < 50
					@attack = @current.species.attacks[rand(2)]
					selection_counter += 1

					if @attack.mp_consumption < @current.current_mp
						not_enough_mp = false
					end
				end

				if selection_counter >= 50
					@attack = Attack.find_by(title: "struggle")
				end

				@current.current_mp = @current.current_mp - @attack.mp_consumption

	    	base_dmg = @attack.base_dmg
	    	dmg_range = @attack.dmg_range

	    	@critical = true if rand > 0.8
	    	@dmg = (base_dmg + rand(dmg_range))
	    	@dmg = (@dmg * 1.8).round if @critical

	    	@target.current_hp -= @dmg if @target.current_hp > 0

		    @target.current_hp = 0 if @target.current_hp < 0

		    FightTurn.create( maker_id: @current.id ,maker_type: "Mob", target_id: @target.id, target_type: "Character", 
		    									damage: @dmg, healed: nil, skill_used: @attack.name, skill_id: @attack.id, skill_type: "Attack", 
		    									item_used: nil,item_used_id: nil,item_used_type: nil, critical: @critical, fight_type: "MobBattle", fight_id: @battle.id  )

	  	  @target.save
	  	  @current.save

    	change_battle_status(@battle)
    end
end