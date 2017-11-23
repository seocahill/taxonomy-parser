class LabelSerializer < TaxonomyParser::BaseSerializer
  has_one :element

  attributes :label, :documentation, :period_start_label, :period_end_label, :verbose_label
end