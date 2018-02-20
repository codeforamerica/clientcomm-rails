ActiveAdmin.register ClientStatus do
  menu false
  permit_params :name, :followup_date, :icon_color, :department
end
