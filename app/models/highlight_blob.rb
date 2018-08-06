class HighlightBlob < ApplicationRecord
  html_fragment :text, scrub: :prune
end
