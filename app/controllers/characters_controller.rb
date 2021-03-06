class CharactersController < ApplicationController
  def index
    @characters = Character.all
  end

  def show
    @character = Character.find(params[:id])
    @skills = []
    @character.skills.each {|skill| @skills << skill.build_skill}
  end

  def new
    @character = Character.new
  end

  def create

    if current_user
      @character = Character.new(char_params)
      @character.assign_attributes(

        level: 1,
        exp: 0,

        max_hp: 100,
        max_mp: 50,
        current_hp: 100,
        current_mp: 50, 
        stat_strength: 4 + rand(2), 
        stat_dex: 4 + rand(2), 
        stat_luck: 4 + rand(2), 
        stat_int: 4 + rand(2),
        battle_status: 'available',
        gold: 50,
        last_location_id: 0,
        avatar_url: "characters/charasmall.png",
        stats_to_spend: 0
        )

      if current_user.selected_character
        @character.selected = false
      else
        @character.selected = true
      end

      if @character.save

        @character.attacks << Attack.find_by(name: 'punch')
        @character.attacks << Attack.find_by(name: 'kick')

        @character.items.create( subclass_id: 2, subclass_type: "Weapon")
        @character.items.create( subclass_id: 1, subclass_type: "Consumable")
        @character.items.create( subclass_id: 2, subclass_type: "Consumable")



        current_user.characters << @character

        redirect_to characters_path, message: "Character Created!"
      else
        render :new, message: "Could not create character"
      end
    else
      redirect_to user_path(current_user.id), message: "huh?"
    end

  end

  def edit
    @character = Character.find(params[:id])
  end

  def update
    @character = Character.find(params[:id])
  end

  def destroy
    @character = Character.find(params[:id])
  end

  def attack

    @target = Character.find(params[:id])
    @base_dmg = 5
    @critical = true if rand > 0.8
    @dmg = (@base_dmg + rand(5))
    @dmg = (@dmg * 1.8).round if @critical

    @target.current_hp -= @dmg if @target.current_hp > 0

    @target.current_hp = 0 if @target.current_hp < 0

    @target.save

    # redirect_to characters_path(cr: @critical, p: @target, d: 1, dmg: @dmg)

    redirect_to :back
  end

  def reset
    @characters = Character.all

    @characters.each do |char|
      char.current_hp = char.max_hp
      char.current_mp = char.max_mp

      char.save
    end

    redirect_to :root
  end

  def select_character
    @character = Character.find(params[:id])

    current_user.select_character_id = @character.id
    current_user.save
  end

  private
  def char_params
    params.require(:character).permit(:name, :gender)
  end
end
