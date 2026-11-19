extends GdUnitTestSuite
## The open-source notices shown in Settings must carry Godot's MIT licence and its bundled
## components (their licences require the notices to ship with the app).


func test_notices_include_godot_licence_and_components() -> void:
	var text := LicensesView.notices()
	assert_str(text).contains("Godot Engine")
	assert_str(text).contains("Permission is hereby granted, free of charge")  # MIT wording
	assert_str(text).contains("FreeType")  # a bundled third-party component
	assert_int(text.length()).is_greater(20000)
