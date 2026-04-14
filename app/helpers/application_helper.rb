module ApplicationHelper
  def sidebar_link(label, path, active: false)
    base_classes = "flex items-center gap-3 px-3 py-2 rounded-md text-sm font-medium transition-colors"
    active_classes = active ? "bg-gray-800 text-white" : "text-gray-300 hover:bg-gray-800 hover:text-white"

    link_to path, class: "#{base_classes} #{active_classes}" do
      content_tag(:span, label)
    end
  end
end
