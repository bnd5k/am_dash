module ApplicationHelper


  def errors_for(model, attribute)
    if model.errors.messages[attribute].present?
      content_tag :span, :class => 'error_message' do
        model.errors[attribute].join(", ")
      end
    end
  end

  def bootstrap_class_for(flash_type)
    case flash_type
    when "success"
      "alert-success"   # Green
    when "error"
      "alert-danger"    # Red
    when "alert"
      "alert-warning"   # Yellow
    when "notice"
      "alert-info"      # Blue
    else
      flash_type.to_s
    end
  end

end
