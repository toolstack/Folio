
blueprint_files = files(
  'window.blp',
  'shortcut_window.blp',
  'preferences.blp',
  'edit_view/edit_view.blp',
  'edit_view/toolbar/toolbar.blp',
  'file_editor/file_editor_window.blp',
  'markdown/heading_popover.blp',
  'markdown_cheatsheet/markdown_cheatsheet.blp',
  'notebook_icon/notebook_preview.blp',
  'notebooks_bar/notebook_create_popup.blp',
  'notebooks_bar/icon.blp',
  'notebooks_bar/notebook_menu.blp',
  'notebooks_bar/notebooks_bar.blp',
  'notebooks_bar/theme_selector.blp',
  'notebook_sidebar/note_card.blp',
  'notebook_sidebar/note_create_popup.blp',
  'notebook_sidebar/note_menu.blp',
  'popup/notebook_selection_popup/notebook_list_item.blp',
  'popup/notebook_selection_popup/notebook_selection_popup.blp',
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