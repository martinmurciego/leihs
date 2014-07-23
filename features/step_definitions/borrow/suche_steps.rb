# -*- encoding : utf-8 -*-

Dann(/^sieht man die Suche$/) do
  visit borrow_root_path
  page.should have_selector(".topbar .topbar-search")
end

Wenn(/^man einen Suchbegriff eingibt$/) do
  step 'man gibt einen Suchbegriff ein'
end

Dann(/^sieht man das Foto, den Namen und den Hersteller der ersten 6 Modelle gemäss aktuellem Suchbegriff$/) do
  page.should have_selector(".ui-autocomplete")
  all(".ui-autocomplete a").length.should >= 6
  6.times do |i|
    first(:xpath, "(//*[contains(@class, 'ui-autocomplete')]//a)[#{i+1}]//strong").text[@search_term].should_not be_nil
    model = @current_user.models.borrowable.find {|m| [m.name, m.product].include? first(:xpath, "(//*[contains(@class, 'ui-autocomplete')]//a)[#{i+1}]//strong").text }
    first(:xpath, "(//*[contains(@class, 'ui-autocomplete')]//a)[#{i+1}]//*[contains(./text(), '#{model.manufacturer}')]")
    first(:xpath, "(//*[contains(@class, 'ui-autocomplete')]//a)[#{i+1}]//img[@src='/models/#{model.id}/image_thumb']")
  end
end

Dann(/^sieht den Link 'Alle Suchresultate anzeigen'$/) do
  page.should have_selector(".ui-autocomplete a", :text => _("Show all search results"))
end

Angenommen(/^man wählt ein Modell von der Vorschlagsliste der Suche$/) do
  step 'man einen Suchbegriff eingibt'
  @model = @current_user.models.find {|m| [m.name, m.product].include? find(".ui-autocomplete a strong", match: :first).text }
  find(".ui-autocomplete a", match: :first, :text => @model.name).click
end

Dann(/^wird die Modell\-Ansichtsseite geöffnet$/) do
  current_path.should eq borrow_model_path(@model)
end

Angenommen(/^man gibt einen Suchbegriff ein$/) do
  @model ||= @current_user.models.borrowable.detect {|m| @current_user.models.borrowable.where("models.product LIKE '%#{m.name[0..3]}%'").length >= 6}
  @search_term = @model.name[0..3]
  fill_in "search_term", :with => @search_term
end

Angenommen(/^drückt ENTER$/) do
  find("#search input[name='search_term']").native.send_keys(:return)
end

Dann(/^wird die Such\-Resultatseite angezeigt$/) do
  find("nav .navigation-tab-item.active", text: _("Search for '%s'") % @search_term)
  current_path.should eq borrow_search_results_path(@search_term)
end

Dann(/^man sieht alle gefundenen Modelle mit Bild, Modellname und Herstellername$/) do
  @models = @current_user.models.borrowable.search(@model.name[0..3], [:manufacturer, :product, :version]).default_order.paginate(page: 1, per_page: 20)
  @models.each do |model|
    within "#model-list .line[data-id='#{model.id}']" do
      find("div .col1of6", :text => model.manufacturer, match: :prefer_exact)
      find("div .col3of6", :text => model.name, match: :prefer_exact)
      find("div .col1of6 img[src='/models/#{model.id}/image_thumb']")
    end
  end
end

Dann(/^man sieht die Sortiermöglichkeit$/) do
  step 'man sieht Sortiermöglichkeiten'
end

Dann(/^man sieht die Geräteparkeinschränkung$/) do
  step 'man sieht die Gerätepark-Auswahl'
end

Dann(/^man sieht die Ausleihzeitraumwahl$/) do
  step 'man sieht die Einschränkungsmöglichkeit eines Ausleihzeitraums'
end

Dann(/^die Vorschlagswerte sind verschwunden$/) do
  page.should_not have_selector(".ui-autocomplete")
end

Wenn(/^ich nach einem Modell suche, welches in nicht ausleihen kann$/) do
  @model = (@current_user.models - @current_user.models.borrowable).sample
end

Dann(/^wird dieses Modell auch nicht in den Suchergebnissen angezeigt$/) do
  step 'man einen Suchbegriff eingibt'
  page.should_not have_content @model.name
  step 'drückt ENTER'
  page.should_not have_content @model.name
end
