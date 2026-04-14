module ApplicationHelper
  include Pagy::Frontend

  def tailwind_pagy_nav(pagy)
    base = "inline-flex items-center justify-center min-w-[36px] h-9 px-3 text-sm font-medium rounded-md border transition-colors"
    link_cls = "#{base} border-gray-300 bg-white text-gray-700 hover:bg-gray-50"
    current_cls = "#{base} border-indigo-600 bg-indigo-600 text-white"
    disabled_cls = "#{base} border-gray-200 bg-gray-50 text-gray-300 cursor-not-allowed"
    gap_cls = "inline-flex items-center justify-center min-w-[36px] h-9 px-2 text-sm text-gray-400"

    html = +""
    html << (pagy.prev ? link_to("&laquo;".html_safe, pagy_url_for(pagy, pagy.prev), class: link_cls) : content_tag(:span, "&laquo;".html_safe, class: disabled_cls))

    pagy.series.each do |item|
      html << case item
      when Integer
        link_to(item.to_s, pagy_url_for(pagy, item), class: link_cls)
      when String
        content_tag(:span, item, class: current_cls)
      when :gap
        content_tag(:span, "…", class: gap_cls)
      else
        ""
      end
    end

    html << (pagy.next ? link_to("&raquo;".html_safe, pagy_url_for(pagy, pagy.next), class: link_cls) : content_tag(:span, "&raquo;".html_safe, class: disabled_cls))
    html.html_safe
  end

  def sidebar_link(label, path, active: false)
    base_classes = "flex items-center gap-3 px-3 py-2 rounded-md text-sm font-medium transition-colors"
    active_classes = active ? "bg-gray-800 text-white" : "text-gray-300 hover:bg-gray-800 hover:text-white"

    link_to path, class: "#{base_classes} #{active_classes}" do
      content_tag(:span, label)
    end
  end
end
