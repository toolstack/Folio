
blueprint_files = files(
  'edit_view/edit_view.blp',
  'edit_view/toolbar/toolbar.blp',
  'edit_view/cheatsheet/markdown_cheatsheet.blp',
  'file_editor/file_editor_window.blp',
  'popup/shortcut_window.blp',
  'popup/notebook_selection_popup/notebook_list_item.blp',
  'popup/notebook_selection_popup/notebook_selection_popup.blp',
  'preferences/preferences.blp',
  'widgets/markdown/heading_popover.blp',
  'widgets/notebook_icon/notebook_preview.blp',
  'widgets/save_indicator/save_indicator.blp',
  'widgets/theme_selector/theme_selector.blp',
  'window/window.blp',
  'window/notebooks_bar/notebook_create_popup.blp',
  'window/notebooks_bar/icon.blp',
  'window/notebooks_bar/notebook_menu.blp',
  'window/notebooks_bar/notebooks_bar.blp',
  'window/sidebar/note_card.blp',
  'window/sidebar/note_create_popup.blp',
  'window/sidebar/note_menu.blp',
)

blueprint_ui = []
foreach blp : blueprint_files
  blueprint_ui += '@0@'.format(blp).replace('.blp', '.ui').split('/')[-1]
endforeach

blueprints = custom_target('blueprints',
  input: blueprint_files,
  output: blueprint_ui,
  command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTDIR@', '@CURRENT_SOURCE_DIR@', '@INPUT@'],
)