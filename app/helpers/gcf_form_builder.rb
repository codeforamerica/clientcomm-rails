class GcfFormBuilder < ActionView::Helpers::FormBuilder
  # rubocop:disable Metrics/ParameterLists
  def gcf_input_field(method, label_text, type: 'text', notes: [], options: {}, classes: [], prefix: nil, autofocus: nil, icon: nil)
    classes = classes.append(%w[text-input])
    <<-HTML.html_safe
      <fieldset class="form-group#{error_state(object, method)}">
        #{label(method, label_contents(label_text, notes, icon))}
        #{prefixed_field(text_field(method, { autofocus: autofocus, type: type, class: classes.join(' '), autocomplete: 'off', autocorrect: 'off', autocapitalize: 'off', spellcheck: 'false' }.merge(options)), prefix: prefix)}
        #{errors_for(object, method)}
      </fieldset>
    HTML
  end
  # rubocop:enable Metrics/ParameterLists

  def gcf_textarea(method, label_text, notes: [], options: {}, classes: [], placeholder: nil, autofocus: nil)
    classes = classes.append(%w[textarea])
    <<-HTML.html_safe
      <fieldset class="form-group#{error_state(object, method)}">
        #{label_and_field(method, label_text, text_area(method, { autofocus: autofocus, class: classes.join(' '), autocomplete: 'off', autocorrect: 'off', autocapitalize: 'off', spellcheck: 'false', placeholder: placeholder }.merge(options)), notes: notes)}
        #{errors_for(object, method)}
      </fieldset>
    HTML
  end

  def gcf_radio_set(method, label_text, collection, notes: [], layout: 'block', variant: '', classes: [])
    <<-HTML.html_safe
      <fieldset class="form-group#{error_state(object, method)}#{(' ' + classes.join(' ')).strip}">
        #{label_contents(label_text, notes)}
        #{radio_buttons(method, collection, layout, variant)}
        #{errors_for(object, method)}
      </fieldset>
    HTML
  end

  def gcf_select(method, label_text, collection, notes: [], include_blank: false, prompt: false)
    <<-HTML.html_safe
      <fieldset class="form-group#{error_state(object, method)}">
        #{label(method, label_contents(label_text, notes))}
        <div class="select">
          #{select(method, collection, { include_blank: include_blank, prompt: prompt }, class: 'select__element')}
        </div>
        #{errors_for(object, method)}
      </fieldset>
    HTML
  end

  def gcf_date_select(method, label_text, notes: [], options: {}, autofocus: nil)
    <<-HTML.html_safe
      <fieldset class="form-group#{error_state(object, method)}">
        #{label(method, label_contents(label_text, notes))}
        <div class="input-group--inline">
          <div class="select">
            #{date_select(method, { autofocus: autofocus, date_separator: '</div><div class="select">' }.merge(options), class: 'select__element')}
          </div>
        </div>
        #{errors_for(object, method)}
      </fieldset>
    HTML
  end

  # Expecting the following hash for each item:
  # {label: "Click me!", method: :some_attribute}
  def gcf_checkbox_set(collection, label_text: nil, notes: [], layout: 'block')
    checkbox_html = <<-HTML.html_safe
      <fieldset class="input-group--#{layout}">
    HTML

    checkbox_html << collection.map do |item|
      method = item[:method]
      label = item[:label]
      gcf_checkbox(method, label)
    end.join.html_safe

    checkbox_html << <<-HTML.html_safe
      </fieldset>
    HTML

    if label_text || notes
      label_html = <<-HTML.html_safe
        #{label_contents(label_text, notes)}
      HTML
      checkbox_html = label_html + checkbox_html
    end

    checkbox_html
  end

  # Expecting the following hash for each item:
  # { label: "Click me!", value: 'some_value' }
  def gcf_collection_check_boxes(method, collection)
    collection_check_boxes method,
                           collection,
                           ->(obj) { obj[:value] },
                           ->(obj) { obj[:label] } do |b|
      b.label(class: 'checkbox') { b.check_box + b.text }
    end.html_safe
  end

  def gcf_checkbox(method, label_text)
    <<-HTML.html_safe
      <label class="checkbox">
        #{check_box_with_label(label_text, method)}
      </label>
    HTML
  end

  def check_box_with_label(label_text, method)
    <<-HTML.html_safe
      #{check_box(method)} #{label_text}
    HTML
  end

  def signature(text = I18n.t('gcf_form_builder.signature.text'))
    submit(text, class: 'button button--primary')
  end

  def continue(text = I18n.t('general.continue'))
    button_body = <<-HTML.html_safe
      #{text}
      <i class="button__icon icon-arrow_forward" aria-hidden='true'></i>
    HTML

    button(button_body, class: 'button button--primary', data: { disable_with: button_body })
  end

  def yes_no
    [{ value: true, label: I18n.t('general.affirmative') }, { value: false, label: I18n.t('general.negative') }]
  end

  def stable_housing
    [
      { value: true, label: I18n.t('gcf_form_builder.stable_housing.affirmative') },
      { value: false, label: I18n.t('gcf_form_builder.stable_housing.negative') }
    ]
  end

  def mailing_address
    [
      { value: true, label: I18n.t('gcf_form_builder.mailing_address.affirmative') },
      { value: false, label: I18n.t('gcf_form_builder.mailing_address.negative') }
    ]
  end

  private

  def label_contents(label_text, notes, icon = nil)
    notes = Array(notes)
    icon_html = ''
    if icon.present?
      icon_html = <<-HTML
        <i class="icon-#{icon} orange"></i>
      HTML
    end
    label_text = <<-HTML
      <p class="form-question">#{label_text}#{icon_html}</p>
    HTML
    notes.each do |note|
      label_text << <<-HTML
        <p class="text--help">#{note}</p>
      HTML
    end
    label_text.html_safe
  end

  def label_and_field(method, label_text, field, notes: [], prefix: nil)
    label(method, label_contents(label_text, notes)) + prefixed_field(field, prefix: prefix)
  end

  def prefixed_field(field, prefix: nil)
    if prefix
      <<-HTML
        <div class="text-input-group">
          <div class="text-input-group__prefix">#{prefix}</div>
          #{field}
        </div>
      HTML
    else
      field
    end
  end

  def radio_buttons(method, collection, layout, variant)
    variant_class = " #{variant}" if variant.present?
    radio_html = <<-HTML
      <radiogroup class="input-group--#{layout}#{variant_class}">
    HTML
    collection.map do |item|
      input_html = item.fetch(:input_html, {})
      radio_html << <<-HTML.html_safe
        <label class="radio-button">
          #{radio_button(method, item[:value], input_html)}
          #{item[:label]}
        </label>
      HTML

      if item[:notes]
        radio_html << <<-HTML.html_safe
        <p class="text--help with-padding-med">You'll be prompted to contact this client <strong>every #{item[:notes]} days</strong></p>
        HTML
      end
    end
    radio_html << <<-HTML
      </radiogroup>
    HTML
    radio_html
  end

  def errors_for(object, method)
    errors = object.errors[method]
    if errors.any?
      <<-HTML
        <div class="text--error">
          <i class="icon-warning"></i>
          #{errors.to_sentence}
        </div>
      HTML
    end
  end

  def error_state(object, method)
    errors = object.errors[method]
    ' form-group--error' if errors.any?
  end
end
