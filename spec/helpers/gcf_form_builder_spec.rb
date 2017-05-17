require "rails_helper"

describe GcfFormBuilder, type: :view do
  let(:template) do
    template = OpenStruct.new(output_buffer: "")
    template.extend ActionView::Helpers::FormHelper
    template.extend ActionView::Helpers::FormTagHelper
    template.extend ActionView::Helpers::FormOptionsHelper
  end

  describe "#gcf_textarea" do
    it "renders a text area" do
      client = create :client
      form_builder = GcfFormBuilder.new(:client, client, template, {})

      output = form_builder.gcf_textarea(:first_name, "Enter your first name in this unnecessarily BIG box!", notes: ["This is a great note.", "Applause, please!"])

      expect(output).to be_html_safe
      expect(output).to match_html <<~HTML
        <fieldset class="form-group">
          <label for="client_first_name">
            <p class="form-question">Enter your first name in this unnecessarily BIG box!</p>
            <p class="text--help">This is a great note.</p>
            <p class="text--help">Applause, please!</p>
          </label>
          <textarea class="textarea" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" name="client[first_name]" id="client_first_name">
          #{client.first_name}</textarea>
      </fieldset>
      HTML
    end

    it "renders with autofocus" do
      client = create :client
      form_builder = GcfFormBuilder.new(:client, client, template, {})

      output = form_builder.gcf_textarea(:first_name, "Enter your first name in this unnecessarily BIG box!", notes: ["This is a great note.", "Applause, please!"], autofocus: true)

      expect(output).to be_html_safe
      expect(output).to match_html <<~HTML
        <fieldset class="form-group">
          <label for="client_first_name">
            <p class="form-question">Enter your first name in this unnecessarily BIG box!</p>
            <p class="text--help">This is a great note.</p>
            <p class="text--help">Applause, please!</p>
          </label>
          <textarea autofocus="autofocus" class="textarea" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" name="client[first_name]" id="client_first_name">
          #{client.first_name}</textarea>
      </fieldset>
      HTML
    end
  end

  describe "#gcf_input_field" do
    it "renders an input field" do
      client = create :client
      form_builder = GcfFormBuilder.new(:client, client, template, {})

      output = form_builder.gcf_input_field(:first_name, "Enter your first name", type: "text", notes: ["This is a great note.", "Applause, please!"])
      expect(output).to be_html_safe
      expect(output).to match_html <<~HTML
        <fieldset class="form-group">
          <label for="client_first_name">
            <p class="form-question">Enter your first name</p>
            <p class="text--help">This is a great note.</p>
            <p class="text--help">Applause, please!</p>
          </label>
          <input type="text" class="text-input" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" value="#{client.first_name}" name="client[first_name]" id="client_first_name" />
        </fieldset>
      HTML
    end

    it "renders with autofocus" do
      client = create :client
      form_builder = GcfFormBuilder.new(:client, client, template, {})

      output = form_builder.gcf_input_field(:first_name, "Enter your first name", type: "text", notes: ["This is a great note.", "Applause, please!"], autofocus: true)
      expect(output).to be_html_safe
      expect(output).to match_html <<~HTML
        <fieldset class="form-group">
          <label for="client_first_name">
            <p class="form-question">Enter your first name</p>
            <p class="text--help">This is a great note.</p>
            <p class="text--help">Applause, please!</p>
          </label>
          <input autofocus="autofocus" type="text" class="text-input" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" value="#{client.first_name}" name="client[first_name]" id="client_first_name" />
        </fieldset>
      HTML
    end

    context 'with no note' do
      it "renders an input field" do
        client = create :client
        form_builder = GcfFormBuilder.new(:client, client, template, {})

        output = form_builder.gcf_input_field(:first_name, "Enter your first name", type: "text", notes: nil)
        expect(output).to be_html_safe
        expect(output).to match_html <<~HTML
          <fieldset class="form-group">
            <label for="client_first_name">
              <p class="form-question">Enter your first name</p>
            </label>
            <input type="text" class="text-input" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" value="#{client.first_name}" name="client[first_name]" id="client_first_name" />
          </fieldset>
        HTML
      end
    end

    context 'with a string supplied as a note' do
      it "renders an input field" do
        client = create :client
        form_builder = GcfFormBuilder.new(:client, client, template, {})

        output = form_builder.gcf_input_field(:first_name, "Enter your first name", type: "text", notes: "This is a great note.")
        expect(output).to be_html_safe
        expect(output).to match_html <<~HTML
          <fieldset class="form-group">
            <label for="client_first_name">
              <p class="form-question">Enter your first name</p>
              <p class="text--help">This is a great note.</p>
            </label>
            <input type="text" class="text-input" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" value="#{client.first_name}" name="client[first_name]" id="client_first_name" />
          </fieldset>
        HTML
      end
    end

    context 'with a $ prefix' do
      it "renders the input prefix" do
        client = create :client
        form_builder = GcfFormBuilder.new(:client, client, template, {})

        output = form_builder.gcf_input_field(:first_name, "Enter your first name", type: "text", notes: nil, prefix: "$")
        expect(output).to be_html_safe
        expect(output).to match_html <<~HTML
          <fieldset class="form-group">
            <label for="client_first_name">
              <p class="form-question">Enter your first name</p>
            </label>
            <div class="text-input-group">
              <div class="text-input-group__prefix">$</div>
              <input type="text" class="text-input" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" value="#{client.first_name}" name="client[first_name]" id="client_first_name" />
            </div>
          </fieldset>
        HTML
      end
    end

    it "renders errors" do
      # client = build :client, phone_number: "BOGUS"
      client = build :client, phone_number: "BOGUS"
      client.valid?
      form_builder = GcfFormBuilder.new(:client, client, template, {})

      output = form_builder.gcf_input_field(:phone_number, "Enter your phone number", type: "number")
      expect(output).to be_html_safe
      expect(output).to match_html <<~HTML
        <fieldset class="form-group form-group--error">
          <div class="field_with_errors">
            <label for="client_phone_number">
              <p class="form-question">Enter your phone number</p>
            </label>
          </div>
          <div class="field_with_errors">
            <input type="number" class="text-input" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" value="BOGUS" name="client[phone_number]" id="client_phone_number" />
          </div>
          <div class="text--error">
            <i class="icon-warning"></i> Make sure the phone number is 10 digits.
          </div>
        </fieldset>
      HTML
    end
  end

  describe "#gcf_select_field" do
    it "renders a select field" do
      client = create :client, active: true
      form_builder = GcfFormBuilder.new(:client, client, template, {})

      output = form_builder.gcf_select(:active, "Is this client active?", %w(Yes No))
      expect(output).to be_html_safe
      expect(output).to match_html <<~HTML
        <fieldset class="form-group">
          <label for="client_active">
            <p class="form-question">Is this client active?</p>
          </label>
          <div class="select">
            <select class="select__element" name="client[active]" id="client_active">
              <option value="Yes">Yes</option>
              <option value="No">No</option>
            </select>
          </div>
        </fieldset>
      HTML
    end
  end

  describe "#gcf_checkbox_set" do
    it "renders a check box set" do
      client = create :client, active: true
      form_builder = GcfFormBuilder.new(:client, client, template, {})

      output = form_builder.gcf_checkbox_set([{ label: "Active", method: :active }, { label: "Still Active", method: :active }], label_text: "TEST LABEL")
      expect(output).to be_html_safe
      expect(output).to match_html <<~HTML
        <p class="form-question">TEST LABEL</p>
        <fieldset class="input-group--block">
          <label class="checkbox">
            <input name="client[active]" type="hidden" value="0" />
            <input type="checkbox" value="1" checked="checked" name="client[active]" id="client_active" /> Active
          </label>
          <label class="checkbox">
            <input name="client[active]" type="hidden" value="0" />
            <input type="checkbox" value="1" checked="checked" name="client[active]" id="client_active" /> Still Active
          </label>
        </fieldset>
      HTML
    end
  end

  describe "#gcf_checkbox" do
    it "renders a check box that is not checked if the preference is false" do
      client = create :client, active: false
      form_builder = GcfFormBuilder.new(:client, client, template, {})

      output = form_builder.gcf_checkbox(:active, "Active")

      expect(output).to be_html_safe
      expect(output).to match_html <<~HTML
        <label class="checkbox">
          <input name="client[active]" type="hidden" value="0" />
          <input type="checkbox" value="1" name="client[active]" id="client_active" /> Active
        </label>
      HTML
    end

    it "renders a check box that is checked when the subscription preference is true" do
      client = create :client, active: true
      form_builder = GcfFormBuilder.new(:client, client, template, {})

      output = form_builder.gcf_checkbox(:active, "Active")

      expect(output).to be_html_safe
      expect(output).to match_html <<~HTML
        <label class="checkbox">
          <input name="client[active]" type="hidden" value="0" />
          <input type="checkbox" value="1" checked="checked" name="client[active]" id="client_active" /> Active
        </label>
      HTML
    end
  end

  describe "#gcf_radio_set" do
    it "render a set of radio buttons" do
      client = create :client
      form_builder = GcfFormBuilder.new(:client, client, template, {})

      output = form_builder.gcf_radio_set(:last_name, "If your last name were a single digit, what would it be?", 1..2)
      expect(output).to be_html_safe
      expect(output).to match_html <<~HTML
        <fieldset class="form-group">
          <p class="form-question">If your last name were a single digit, what would it be?</p>
          <radiogroup class="input-group--block">
            <label class="radio-button">
              <input type="radio" value="1" name="client[last_name]" id="client_last_name_1" /> 1
            </label>
            <label class="radio-button">
              <input type="radio" value="2" name="client[last_name]" id="client_last_name_2" /> 2
            </label>
          </radiogroup>
        </fieldset>
      HTML
    end

    it "renders a set of radio buttons with labels that differ from values" do
      client = create :client
      form_builder = GcfFormBuilder.new(:client, client, template, {})

      output = form_builder.gcf_radio_set(:last_name, "What's your last name?", [{ value: 1, label: "Gutierrez" }, { value: 2, label: "Livingston" }])
      expect(output).to be_html_safe
      expect(output).to match_html <<~HTML
        <fieldset class="form-group">
          <p class="form-question">What's your last name?</p>
          <radiogroup class="input-group--block">
            <label class="radio-button">
              <input type="radio" value="1" name="client[last_name]" id="client_last_name_1" /> Gutierrez
            </label>
            <label class="radio-button">
              <input type="radio" value="2" name="client[last_name]" id="client_last_name_2" /> Livingston
            </label>
          </radiogroup>
        </fieldset>
      HTML
    end
  end

  describe "#continue" do
    it "renders a continue button" do
      client = create :client
      form_builder = GcfFormBuilder.new(:client, client, template, {})
      output = form_builder.continue "Let's Go!"
      expect(output).to be_html_safe
      expect(output).to match_html <<~HTML
        <button name="button" type="submit" class="button button--primary" data-disable-with=" Let's Go! &lt;i class=&quot;button__icon icon-arrow_forward&quot; aria-hidden='true'&gt;&lt;/i&gt; "> Let's Go! <i class="button__icon icon-arrow_forward" aria-hidden="true"></i></button>
      HTML
    end
  end
end
