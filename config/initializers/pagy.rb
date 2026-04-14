require "pagy"

Pagy::DEFAULT[:limit] = 20
Pagy::DEFAULT[:size] = 7

require "pagy/extras/overflow"
Pagy::DEFAULT[:overflow] = :last_page

