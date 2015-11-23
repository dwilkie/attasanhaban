# Disregard images that don't have whitespace and to the left
# Otherwise the letters will be cutoff

require 'rmagick'
require 'tesseract'

ID_MIN_START_Y = 400
ID_MAX_START_Y = 600
ID_MIN_START_X = 500
ID_MAX_START_X = 800

ID_COLUMN_HEIGHT = 85
ID_COLUMN_WIDTH = 700

Y_INCREMENT = 20
X_INCREMENT = 20

THRESHOLD_RANGE = 25..45
THRESHOLD_STEP = 5

WHITESPACE_THICKNESS = 2

output_path = "./test_images/output"
image_path = "./test_images/ma_low_res_cropped.png"
image_path2 = "./test_images/mara_low_res_cropped.png"

image = Magick::ImageList.new(image_path)

images = []
image_counter = 0

ENV["TESSDATA_PREFIX"]="/usr/share/tesseract-ocr"
e = Tesseract::Engine.new
e.whitelist = (0..9).map(&:to_s)

results = {}

(ID_MIN_START_Y..ID_MAX_START_Y).step(Y_INCREMENT) do |y|
  (ID_MIN_START_X..ID_MAX_START_X).step(X_INCREMENT) do |x|
    cropped_image = image.crop(x, y, ID_COLUMN_WIDTH, ID_COLUMN_HEIGHT, true)
    THRESHOLD_RANGE.step(THRESHOLD_STEP) do |threshold|
      image_counter += 1
      threshold_image = cropped_image.threshold(Magick::QuantumRange * (threshold / 100.0))

      header = threshold_image.crop(0, 0, ID_COLUMN_WIDTH, WHITESPACE_THICKNESS, true)
      footer = threshold_image.crop(0, ID_COLUMN_HEIGHT - WHITESPACE_THICKNESS, ID_COLUMN_WIDTH, WHITESPACE_THICKNESS, true)

      header_white = true

      header.each_pixel do |pixel|
        header_white = (header_white && pixel.to_color == 'white')
        break if !header_white
      end

      footer_white = true

      footer.each_pixel do |pixel|
        footer_white = (footer_white && pixel.to_color == 'white')
        break if !footer_white
      end

      break if !header_white || !footer_white

      ocr_text = e.text_for(threshold_image).strip
      id_card_regexp = /\A\d{9}\z/
      threshold_image.format = "png"
#      threshold_image.write("#{output_path}/#{x}_#{y}_correct.png") if ocr_text =~ id_card_regexp
#      threshold_image.write("#{output_path}/#{x}_#{y}_#{threshold}.png") if x == ID_MAX_START_X
      if ocr_text =~ id_card_regexp
        threshold_image.write("#{output_path}/#{x}_#{y}_#{threshold}_#{ocr_text}.png")
        results[ocr_text] ||= 0
        results[ocr_text] += 1
      end
    end
  end
end

p results
p "OCR ID: #{results.max_by{|k, v| v}[0]}"
