require "rails_helper"

describe GcfFormBuilder, type: :view do
  let(:template) do
    template = OpenStruct.new(output_buffer: "")
    template.extend ActionView::Helpers::FormHelper
    template.extend ActionView::Helpers::FormTagHelper
    template.extend ActionView::Helpers::FormOptionsHelper
  end

  describe "#gcf_textarea" do
    it 'renders a text area' do
      address = create :address
      form_builder = GcfFormBuilder.new(:address, address, template, {})

      output = form_builder.gcf_textarea(:zip, "Enter your zip in this unnecessarily BIG box!", notes: ["This is a great note.", "Applause, please!"])

      expect(output).to be_html_safe
      expect(output).to match_html <<-HTML
        <fieldset class="form-group">
         <label for="address_zip">
           <p class="form-question">Enter your zip in this unnecessarily BIG box!</p>
           <p class="text--help">This is a great note.</p>
           <p class="text--help">Applause, please!</p>
         </label>
         <textarea class="textarea" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" name="address[zip]" id="address_zip" > 94606</textarea>
       </fieldset>
      HTML
    end

    it 'renders with autofocus' do
      address = create :address
      form_builder = GcfFormBuilder.new(:address, address, template, {})

      output = form_builder.gcf_textarea(:zip, "Enter your zip in this unnecessarily BIG box!", notes: ["This is a great note.", "Applause, please!"], autofocus: true)

      expect(output).to be_html_safe
      expect(output).to match_html <<-HTML
        <fieldset class="form-group">
          <label for="address_zip">
           <p class="form-question">Enter your zip in this unnecessarily BIG box!</p>
           <p class="text--help">This is a great note.</p>
           <p class="text--help">Applause, please!</p>
          </label>
          <textarea autofocus="autofocus" class="textarea" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" name="address[zip]" id="address_zip" > 94606</textarea>
        </fieldset>
      HTML
    end
  end

  describe "#gcf_input_field" do
    it "renders a input field" do
      address = create :address
      form_builder = GcfFormBuilder.new(:address, address, template, {})

      output = form_builder.gcf_input_field(:zip, "Enter your zip", type: "number", notes: ["This is a great note.", "Applause, please!"])
      expect(output).to be_html_safe
      expect(output).to match_html <<-HTML
        <fieldset class="form-group">
         <label for="address_zip">
           <p class="form-question">Enter your zip</p>
           <p class="text--help">This is a great note.</p>
           <p class="text--help">Applause, please!</p>
         </label>
         <input type="number" class="text-input" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" value="94606" name="address[zip]" id="address_zip" />
       </fieldset>
      HTML
    end

    it "renders with autofocus" do
      address = create :address
      form_builder = GcfFormBuilder.new(:address, address, template, {})

      output = form_builder.gcf_input_field(:zip, "Enter your zip", type: "number", notes: ["This is a great note.", "Applause, please!"], autofocus: true)
      expect(output).to be_html_safe
      expect(output).to match_html <<-HTML
        <fieldset class="form-group">
         <label for="address_zip">
           <p class="form-question">Enter your zip</p>
           <p class="text--help">This is a great note.</p>
           <p class="text--help">Applause, please!</p>
         </label>
         <input autofocus="autofocus" type="number" class="text-input" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" value="94606" name="address[zip]" id="address_zip" />
       </fieldset>
      HTML
    end

    context 'with no note' do
      it "renders a input field" do
        address = create :address
        form_builder = GcfFormBuilder.new(:address, address, template, {})

        output = form_builder.gcf_input_field(:zip, "Enter your zip", type: "number", notes: nil)
        expect(output).to be_html_safe
        expect(output).to match_html <<-HTML
          <fieldset class="form-group">
            <label for="address_zip">
             <p class="form-question">Enter your zip</p>
            </label>
            <input type="number" class="text-input" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" value="94606" name="address[zip]" id="address_zip" />
          </fieldset>
        HTML
      end
    end

    context 'with a string supplied as a note' do
      it "renders a input field" do
        address = create :address
        form_builder = GcfFormBuilder.new(:address, address, template, {})

        output = form_builder.gcf_input_field(:zip, "Enter your zip", type: "number", notes: "This is a great note.")
        expect(output).to be_html_safe
        expect(output).to match_html <<-HTML
          <fieldset class="form-group">
            <label for="address_zip">
              <p class="form-question">Enter your zip</p>
              <p class="text--help">This is a great note.</p>
            </label>
            <input type="number" class="text-input" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" value="94606" name="address[zip]" id="address_zip" />
          </fieldset>
        HTML
      end
    end

    context 'with a $ prefix' do
      it "renders the input prefix" do
        eligibility_check = create :eligibility_check
        form_builder = GcfFormBuilder.new(:eligibility_check, eligibility_check, template, {})

        output = form_builder.gcf_input_field(:monthly_gross_income, "MONEY", type: "number", notes: nil, prefix: "$")
        expect(output).to be_html_safe
        expect(output).to match_html <<-HTML
          <fieldset class="form-group">
            <label for="eligibility_check_monthly_gross_income">
              <p class="form-question">MONEY</p>
            </label>
            <div class="text-input-group">
              <div class="text-input-group__prefix">$</div>
              <input type="number" class="text-input" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" value="1" name="eligibility_check[monthly_gross_income]" id="eligibility_check_monthly_gross_income" />
            </div>
          </fieldset>
        HTML
      end
    end

    it "renders errors" do
      address = build :address, zip: "BOGUS"
      address.valid?
      form_builder = GcfFormBuilder.new(:address, address, template, {})

      output = form_builder.gcf_input_field(:zip, "Enter your zip", type: "number")
      expect(output).to be_html_safe
      expect(output).to match_html <<-HTML
        <fieldset class="form-group form-group--error">
         <label for="address_zip">
           <p class="form-question">Enter your zip</p>
         </label>
         <input type="number" class="text-input" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" value="BOGUS" name="address[zip]" id="address_zip" />
         <div class="text--error"><i class="icon-warning"></i> Make sure your ZIP code is 5 digits. </div>
       </fieldset>
      HTML
    end
  end

  describe "#gcf_select_field" do
    it "renders a select field" do
      member = create :member, language: 'English'
      form_builder = GcfFormBuilder.new(:member, member, template, {})

      output = form_builder.gcf_select(:language, "Enter your language", %w(English Spanish))
      expect(output).to be_html_safe
      expect(output).to match_html <<-HTML
        <fieldset class="form-group">
         <label for="member_language">
           <p class="form-question">Enter your language</p>
         </label>
         <div class="select">
           <select class="select__element" name="member[language]" id="member_language">
             <option selected="selected" value="English">English</option>
             <option value="Spanish">Spanish</option>
           </select>
         </div>
       </fieldset>
      HTML
    end
  end

  describe "#gcf_checkbox_set" do
    let!(:subscription_preference) { build :subscription_preference }

    specify do
      form_builder = GcfFormBuilder.new(:subscription_preference, subscription_preference, template, {})
      output = form_builder.gcf_checkbox_set([{ label: "Email me", method: :email_consent }, { label: "Text message me", method: :sms_consent }], label_text: "TEST LABEL")

      expect(output).to match_html <<-HTML
        <p class="form-question">TEST LABEL</p>
        <fieldset class="input-group--block">
          <label class="checkbox"><input name="subscription_preference[email_consent]" type="hidden" value="0" /><input type="checkbox" value="1" checked="checked" name="subscription_preference[email_consent]" id="subscription_preference_email_consent" /> Email me </label>
          <label class="checkbox"><input name="subscription_preference[sms_consent]" type="hidden" value="0" /><input type="checkbox" value="1" checked="checked" name="subscription_preference[sms_consent]" id="subscription_preference_sms_consent" /> Text message me </label>
        </fieldset>
      HTML
    end
  end

  describe "#gcf_checkbox" do
    let!(:subscription_preference) { build :subscription_preference }

    it 'renders a check box that is not checked if the preference is false' do
      subscription_preference.update_attribute(:sms_consent, false)
      form_builder = GcfFormBuilder.new(:subscription_preference, subscription_preference, template, {})
      output = form_builder.gcf_checkbox(:sms_consent, "Text message me")

      expect(output).to match_html <<-HTML
        <label class="checkbox"><input name="subscription_preference[sms_consent]" type="hidden" value="0" /><input type="checkbox" value="1" name="subscription_preference[sms_consent]" id="subscription_preference_sms_consent" /> Text message me </label>
      HTML
    end

    it "renders a check box that is checked when the subscription preference is true" do
      subscription_preference.update_attribute(:sms_consent, true)
      form_builder = GcfFormBuilder.new(:subscription_preference, subscription_preference, template, {})
      output = form_builder.gcf_checkbox(:sms_consent, "Text message me")

      expect(output).to be_html_safe
      expect(output).to match_html <<-HTML
        <label class="checkbox"><input name="subscription_preference[sms_consent]" type="hidden" value="0" /><input type="checkbox" value="1" checked="checked" name="subscription_preference[sms_consent]" id="subscription_preference_sms_consent" /> Text message me </label>
      HTML
    end
  end

  describe "#gcf_radio_set" do
    it "render a set of radio buttons" do
      eligibility_check = build :eligibility_check, household_size: 2
      form_builder = GcfFormBuilder.new(:eligibility_check, eligibility_check, template, {})

      output = form_builder.gcf_radio_set(:household_size, "How many people live in your address?", 1..2)
      expect(output).to be_html_safe
      expect(output).to match_html <<-HTML
        <fieldset class="form-group">
          <p class="form-question">How many people live in your address?</p>
          <radiogroup class="input-group--block">
            <label class="radio-button"><input type="radio" value="1" name="eligibility_check[household_size]" id="eligibility_check_household_size_1" /> 1 </label>
            <label class="radio-button"><input type="radio" value="2" checked="checked" name="eligibility_check[household_size]" id="eligibility_check_household_size_2" /> 2 </label>
          </radiogroup>
        </fieldset>
      HTML
    end

    it "render a set of radio buttons with labels that differ from values" do
      eligibility_check = build :eligibility_check, household_size: 2
      form_builder = GcfFormBuilder.new(:eligibility_check, eligibility_check, template, {})

      output = form_builder.gcf_radio_set(:household_size, "How many people live in your address?", [{ value: 1, label: "One" }, { value: 2, label: "Two" }])
      expect(output).to be_html_safe
      expect(output).to match_html <<-HTML
        <fieldset class="form-group">
         <p class="form-question">How many people live in your address?</p>
         <radiogroup class="input-group--block">
           <label class="radio-button"><input type="radio" value="1" name="eligibility_check[household_size]" id="eligibility_check_household_size_1" /> One </label>
           <label class="radio-button"><input type="radio" value="2" checked="checked" name="eligibility_check[household_size]" id="eligibility_check_household_size_2" /> Two </label>
         </radiogroup>
       </fieldset>
      HTML
    end
  end

  describe "#continue" do
    specify do
      form_builder = GcfFormBuilder.new(:eligibility_check, Object.new, template, {})
      output = form_builder.continue "Let's Go!"
      expect(output).to be_html_safe
      expect(output).to match_html <<-HTML
        <button name="button" type="submit" class="button button--primary" data-disable-with=" Let's Go! &lt;i class=&quot;button__icon icon-arrow_forward&quot; aria-hidden='true'&gt;&lt;/i&gt; "> Let's Go! <i class="button__icon icon-arrow_forward" aria-hidden="true"></i></button>
      HTML
    end
  end
end
