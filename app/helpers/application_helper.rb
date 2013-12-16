module ApplicationHelper

  def flash_class(type)

    case type
    when :alert
      "alert-error"
    when :notice
      "alert-success"
    else
      ""
    end
  end

	def current_char
    if current_user.selected_character
  	  Character.find(current_user.selected_character)
    else
      false
    end
  end

	def battle_session
    if current_char.battle_session
		  current_char.battle_session
    else
      nil
    end
	end
end
