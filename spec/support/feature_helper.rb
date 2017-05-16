module FeatureHelper
  def xstep(title)
    puts "PENDING STEP SKIPPED: #{title}" if ENV["LOUD_TESTS"]
  end

  def step(title)
    puts "STEP: #{title}" if ENV["LOUD_TESTS"]
    yield
  end

  def save_and_open_preview
    file_preview_url = file_preview_url(host: "localhost:3000", file: save_page)
    `open #{file_preview_url}`
  end

  def wut
    save_and_open_preview
  end

  def flash
    find(".flash").text
  end

  def table_contents(selector, header: true)
    [].tap do |contents|
      within(selector) do
        if header
          all("thead tr").map do |tr|
            contents << tr.all("th").map(&:text)
          end
        end
        all("tbody tr").map do |tr|
          contents << tr.all("th, td").map(&:text)
        end
      end
    end
  end

  def on_page(page_title)
    expect(page.title).to eq page_title
    puts "PAGE: #{page_title}" if ENV["LOUD_TESTS"]
    # Protection against missed i18n links
    expect(page).not_to have_text("{")
    yield
  end
end
