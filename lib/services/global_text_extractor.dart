import 'package:flutter/material.dart';

/// Service for extracting all readable text from Flutter widgets
class GlobalTextExtractor {
  static final GlobalTextExtractor _instance = GlobalTextExtractor._internal();
  factory GlobalTextExtractor() => _instance;
  GlobalTextExtractor._internal();

  /// Extract all text from a widget tree
  static String extractAllText(Widget widget) {
    final extractor = _TextExtractor();
    extractor._extractFromWidget(widget);
    return extractor._textBuffer.toString().trim();
  }

  /// Extract text from a specific context (screen)
  static String extractTextFromContext(BuildContext context) {
    final extractor = _TextExtractor();
    
    try {
      // Get the scaffold if it exists
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      if (scaffold != null) {
        extractor._extractFromScaffold(scaffold);
      } else {
        // Fallback: extract from the current widget
        final currentWidget = context.widget;
        extractor._extractFromWidget(currentWidget);
      }
      
      // If no text found, try to extract from the entire widget tree
      if (extractor._textBuffer.toString().trim().isEmpty) {
        extractor._extractFromEntireWidgetTree(context);
      }
    } catch (e) {
      debugPrint('Error extracting text from context: $e');
    }
    
    return extractor._textBuffer.toString().trim();
  }

  /// Extract text from a specific widget
  static String extractTextFromWidget(Widget widget) {
    final extractor = _TextExtractor();
    extractor._extractFromWidget(widget);
    return extractor._textBuffer.toString().trim();
  }
}

class _TextExtractor {
  final StringBuffer _textBuffer = StringBuffer();
  final Set<String> _processedTexts = {};

  void _extractFromScaffold(Scaffold scaffold) {
    // Extract AppBar text
    if (scaffold.appBar != null) {
      _extractFromWidget(scaffold.appBar!);
    }

    // Extract body text
    if (scaffold.body != null) {
      _extractFromWidget(scaffold.body!);
    }

    // Extract floating action button text
    if (scaffold.floatingActionButton != null) {
      _extractFromWidget(scaffold.floatingActionButton!);
    }

    // Extract bottom navigation bar text
    if (scaffold.bottomNavigationBar != null) {
      _extractFromWidget(scaffold.bottomNavigationBar!);
    }

    // Extract drawer text
    if (scaffold.drawer != null) {
      _extractFromWidget(scaffold.drawer!);
    }

    // Extract end drawer text
    if (scaffold.endDrawer != null) {
      _extractFromWidget(scaffold.endDrawer!);
    }
  }

  void _extractFromWidget(Widget widget) {
    try {
      // Handle different widget types
      if (widget is Text) {
        _addText(widget.data ?? '');
      } else if (widget is RichText) {
        _addText(widget.text.toPlainText());
      } else if (widget is TextField) {
        _addTextField(widget);
      } else if (widget is TextFormField) {
        _addTextField(widget);
      } else if (widget is IconButton) {
        _addTooltip(widget.tooltip);
      } else if (widget is FloatingActionButton) {
        _addTooltip(widget.tooltip);
      } else if (widget is ElevatedButton) {
        _addButton(widget.child);
      } else if (widget is OutlinedButton) {
        _addButton(widget.child);
      } else if (widget is TextButton) {
        _addButton(widget.child);
      } else if (widget is ListTile) {
        _addListTile(widget);
      } else if (widget is Card) {
        if (widget.child != null) {
          _extractFromWidget(widget.child!);
        }
      } else if (widget is Container) {
        if (widget.child != null) {
          _extractFromWidget(widget.child!);
        }
      } else if (widget is Padding) {
        if (widget.child != null) {
          _extractFromWidget(widget.child!);
        }
      } else if (widget is Center) {
        if (widget.child != null) {
          _extractFromWidget(widget.child!);
        }
      } else if (widget is Align) {
        if (widget.child != null) {
          _extractFromWidget(widget.child!);
        }
      } else if (widget is Expanded) {
        _extractFromWidget(widget.child);
      } else if (widget is Flexible) {
        _extractFromWidget(widget.child);
      } else if (widget is SizedBox) {
        if (widget.child != null) {
          _extractFromWidget(widget.child!);
        }
      } else if (widget is Column) {
        _extractFromChildren(widget.children);
      } else if (widget is Row) {
        _extractFromChildren(widget.children);
      } else if (widget is Wrap) {
        _extractFromChildren(widget.children);
      } else if (widget is Stack) {
        _extractFromChildren(widget.children);
      } else if (widget is ListView) {
        // ListView doesn't have direct children access
        // Skip or handle differently
      } else if (widget is GridView) {
        // GridView doesn't have direct children access
        // Skip or handle differently
      } else if (widget is SingleChildScrollView) {
        if (widget.child != null) {
          _extractFromWidget(widget.child!);
        }
      } else if (widget is PageView) {
        // PageView doesn't have direct children access
        // Skip or handle differently
      } else if (widget is TabBarView) {
        _extractFromChildren(widget.children);
      } else if (widget is DefaultTabController) {
        _extractFromWidget(widget.child);
      } else if (widget is TabController) {
        // TabController doesn't have children, skip
      } else if (widget is AppBar) {
        _addAppBar(widget);
      } else if (widget is BottomNavigationBar) {
        _addBottomNavigationBar(widget);
      } else if (widget is Drawer) {
        if (widget.child != null) {
          _extractFromWidget(widget.child!);
        }
      } else if (widget is NavigationDrawer) {
        // NavigationDrawer doesn't have direct child access
        // Skip or handle differently
      } else if (widget is Dialog) {
        if (widget.child != null) {
          _extractFromWidget(widget.child!);
        }
      } else if (widget is AlertDialog) {
        _addAlertDialog(widget);
      } else if (widget is SimpleDialog) {
        _addSimpleDialog(widget);
      } else if (widget is SnackBar) {
        _addText(widget.content.toString());
      } else if (widget is Chip) {
        _addChip(widget);
      } else if (widget is ActionChip) {
        _addChip(widget);
      } else if (widget is FilterChip) {
        _addChip(widget);
      } else if (widget is ChoiceChip) {
        _addChip(widget);
      } else if (widget is InputChip) {
        _addChip(widget);
      } else if (widget is Switch) {
        _addSwitch(widget);
      } else if (widget is Checkbox) {
        _addCheckbox(widget);
      } else if (widget is Radio) {
        _addRadio(widget);
      } else if (widget is Slider) {
        _addSlider(widget);
      } else if (widget is DropdownButton) {
        _addDropdownButton(widget);
      } else if (widget is PopupMenuButton) {
        _addTooltip(widget.tooltip);
      } else if (widget is Tooltip) {
        _addTooltip(widget.message);
      } else if (widget is ExpansionTile) {
        _addExpansionTile(widget);
      } else if (widget is CheckboxListTile) {
        _addCheckboxListTile(widget);
      } else if (widget is RadioListTile) {
        _addRadioListTile(widget);
      } else if (widget is SwitchListTile) {
        _addSwitchListTile(widget);
      } else if (widget is DataTable) {
        _addDataTable(widget);
      } else if (widget is DataColumn) {
        _addText((widget as DataColumn).label.toString());
      } else if (widget is DataRow) {
        _addDataRow(widget as DataRow);
      } else if (widget is DataCell) {
        final dataCell = widget as DataCell;
        _extractFromWidget(dataCell.child);
      } else if (widget is Table) {
        _addTable(widget);
      } else if (widget is TableRow) {
        _addTableRow(widget as TableRow);
      } else if (widget is TableCell) {
        final tableCell = widget as TableCell;
        _extractFromWidget(tableCell.child);
      } else if (widget is Stepper) {
        _addStepper(widget);
      } else if (widget is Step) {
        _addStep(widget as Step);
      } else if (widget is LinearProgressIndicator) {
        _addText('Voortgangsbalk');
      } else if (widget is CircularProgressIndicator) {
        _addText('Laden');
      } else if (widget is RefreshIndicator) {
        _extractFromWidget(widget.child);
      } else if (widget is Dismissible) {
        _extractFromWidget(widget.child);
      } else if (widget is Draggable) {
        _extractFromWidget(widget.child);
      } else if (widget is DragTarget) {
        // DragTarget doesn't have a direct child property
        // Skip or handle differently
      } else if (widget is ReorderableListView) {
        // ReorderableListView doesn't have direct children access
        // Skip or handle differently
      } else if (widget is ReorderableList) {
        // ReorderableList doesn't have direct children access
        // Skip or handle differently
      } else if (widget is IndexedStack) {
        _extractFromChildren(widget.children);
      } else if (widget is AnimatedSwitcher) {
        if (widget.child != null) {
          _extractFromWidget(widget.child!);
        }
      } else if (widget is AnimatedCrossFade) {
        if (widget.firstChild != null) {
          _extractFromWidget(widget.firstChild!);
        }
        if (widget.secondChild != null) {
          _extractFromWidget(widget.secondChild!);
        }
      } else if (widget is Hero) {
        if (widget.child != null) {
          _extractFromWidget(widget.child!);
        }
      } else if (widget is FadeTransition) {
        if (widget.child != null) {
          _extractFromWidget(widget.child!);
        }
      } else if (widget is ScaleTransition) {
        if (widget.child != null) {
          _extractFromWidget(widget.child!);
        }
      } else if (widget is RotationTransition) {
        if (widget.child != null) {
          _extractFromWidget(widget.child!);
        }
      } else if (widget is SlideTransition) {
        if (widget.child != null) {
          _extractFromWidget(widget.child!);
        }
      } else if (widget is Positioned) {
        if (widget.child != null) {
          _extractFromWidget(widget.child!);
        }
      } else if (widget is SafeArea) {
        if (widget.child != null) {
          _extractFromWidget(widget.child!);
        }
      } else if (widget is MediaQuery) {
        if (widget.child != null) {
          _extractFromWidget(widget.child!);
        }
      } else if (widget is Theme) {
        if (widget.child != null) {
          _extractFromWidget(widget.child!);
        }
      } else if (widget is DefaultTextStyle) {
        if (widget.child != null) {
          _extractFromWidget(widget.child!);
        }
      } else if (widget is Directionality) {
        if (widget.child != null) {
          _extractFromWidget(widget.child!);
        }
      } else if (widget is Localizations) {
        if (widget.child != null) {
          _extractFromWidget(widget.child!);
        }
      } else if (widget is Builder) {
        // Builder doesn't have direct child access
        // Skip or handle differently
        // Builder's child is created by the builder function, not accessible directly
      } else if (widget is InkWell) {
        // Handle InkWell (commonly used in forum posts)
        if (widget.child != null) {
          _extractFromWidget(widget.child!);
        }
      } else if (widget is GestureDetector) {
        // Handle GestureDetector (commonly used in forum posts)
        if (widget.child != null) {
          _extractFromWidget(widget.child!);
        }
      } else if (widget is StatefulWidget) {
        // Skip stateful widgets that don't have children
      } else if (widget is StatelessWidget) {
        // Skip stateless widgets that don't have children
      } else if (widget is RenderObjectWidget) {
        // Skip render object widgets
      } else if (widget is ProxyWidget) {
        _extractFromWidget(widget.child);
      } else if (widget is ParentDataWidget) {
        _extractFromWidget(widget.child);
      } else if (widget is InheritedWidget) {
        _extractFromWidget(widget.child);
      } else if (widget is MultiChildRenderObjectWidget) {
        _extractFromChildren(widget.children);
      } else if (widget is SingleChildRenderObjectWidget) {
        if (widget.child != null) {
          _extractFromWidget(widget.child!);
        }
      } else if (widget is LeafRenderObjectWidget) {
        // Skip leaf render object widgets
      } else if (widget is RenderObject) {
        // Skip render objects
      } else if (widget is Element) {
        // Skip elements
      } else if (widget is RenderBox) {
        // Skip render boxes
      } else if (widget is RenderObject) {
        // Skip render objects
      } else if (widget is Widget) {
        // Generic widget - try to extract from child if it exists
        try {
          final child = (widget as dynamic).child;
          if (child is Widget) {
            _extractFromWidget(child);
          }
        } catch (e) {
          // Ignore errors when trying to access child
        }
      }
    } catch (e) {
      debugPrint('Error extracting text from widget: $e');
    }
  }

  void _extractFromChildren(List<Widget> children) {
    for (final child in children) {
      _extractFromWidget(child);
    }
  }

  /// Extract text from the entire widget tree using element traversal
  void _extractFromEntireWidgetTree(BuildContext context) {
    try {
      // Try to find all text elements in the widget tree
      final element = context as Element;
      _traverseElementTree(element);
    } catch (e) {
      debugPrint('Error traversing element tree: $e');
    }
  }

  /// Traverse the element tree to find text
  void _traverseElementTree(Element element) {
    try {
      // Check if this element has a widget with text
      final widget = element.widget;
      if (widget is Text) {
        _addText(widget.data ?? '');
      } else if (widget is RichText) {
        _addText(widget.text.toPlainText());
      }
      
      // Traverse children
      element.visitChildren(_traverseElementTree);
    } catch (e) {
      // Skip elements that can't be traversed
    }
  }

  void _addText(String text) {
    if (text.trim().isNotEmpty && !_processedTexts.contains(text)) {
      _processedTexts.add(text);
      _textBuffer.write('$text. ');
    }
  }

  void _addTooltip(String? tooltip) {
    if (tooltip != null && tooltip.trim().isNotEmpty) {
      _addText(tooltip);
    }
  }

  void _addTextField(Widget field) {
    try {
      final controller = (field as dynamic).controller;
      if (controller != null && controller.text.isNotEmpty) {
        _addText('Invoerveld: ${controller.text}');
      } else {
        _addText('Invoerveld beschikbaar');
      }
    } catch (e) {
      _addText('Invoerveld beschikbaar');
    }
  }

  void _addButton(Widget? child) {
    if (child is Text) {
      _addText('Knop: ${child.data}');
    } else if (child is RichText) {
      _addText('Knop: ${child.text.toPlainText()}');
    } else if (child is Icon) {
      _addText('Knop met icoon');
    } else if (child is Row) {
      _extractFromChildren(child.children);
    } else if (child is Column) {
      _extractFromChildren(child.children);
    } else {
      _addText('Knop');
    }
  }

  void _addListTile(ListTile tile) {
    if (tile.title is Text) {
      _addText((tile.title as Text).data ?? '');
    } else if (tile.title is RichText) {
      _addText((tile.title as RichText).text.toPlainText());
    }
    
    if (tile.subtitle is Text) {
      _addText((tile.subtitle as Text).data ?? '');
    } else if (tile.subtitle is RichText) {
      _addText((tile.subtitle as RichText).text.toPlainText());
    }
    
    if (tile.leading != null) {
      _extractFromWidget(tile.leading!);
    }
    
    if (tile.trailing != null) {
      _extractFromWidget(tile.trailing!);
    }
  }

  void _addAppBar(AppBar appBar) {
    if (appBar.title is Text) {
      _addText('Titel: ${(appBar.title as Text).data}');
    } else if (appBar.title is RichText) {
      _addText('Titel: ${(appBar.title as RichText).text.toPlainText()}');
    }
    
    if (appBar.actions != null) {
      for (final action in appBar.actions!) {
        _extractFromWidget(action);
      }
    }
  }

  void _addBottomNavigationBar(BottomNavigationBar bar) {
    for (final item in bar.items) {
      _addText('Tab: ${item.label}');
    }
  }

  void _addAlertDialog(AlertDialog dialog) {
    if (dialog.title is Text) {
      _addText('Dialog titel: ${(dialog.title as Text).data}');
    } else if (dialog.title is RichText) {
      _addText('Dialog titel: ${(dialog.title as RichText).text.toPlainText()}');
    }
    
    if (dialog.content is Text) {
      _addText('Dialog inhoud: ${(dialog.content as Text).data}');
    } else if (dialog.content is RichText) {
      _addText('Dialog inhoud: ${(dialog.content as RichText).text.toPlainText()}');
    } else if (dialog.content is Widget) {
      _extractFromWidget(dialog.content as Widget);
    }
    
    if (dialog.actions != null) {
      for (final action in dialog.actions!) {
        _extractFromWidget(action);
      }
    }
  }

  void _addSimpleDialog(SimpleDialog dialog) {
    if (dialog.title is Text) {
      _addText('Dialog titel: ${(dialog.title as Text).data}');
    } else if (dialog.title is RichText) {
      _addText('Dialog titel: ${(dialog.title as RichText).text.toPlainText()}');
    }
    
    if (dialog.children != null) {
      for (final child in dialog.children!) {
        _extractFromWidget(child);
      }
    }
  }

  void _addChip(Widget chip) {
    try {
      final label = (chip as dynamic).label;
      if (label is Text) {
        _addText('Chip: ${label.data}');
      } else if (label is RichText) {
        _addText('Chip: ${label.text.toPlainText()}');
      } else {
        _addText('Chip');
      }
    } catch (e) {
      _addText('Chip');
    }
  }

  void _addSwitch(Switch switchWidget) {
    _addText('Schakelaar: ${switchWidget.value ? 'aan' : 'uit'}');
  }

  void _addCheckbox(Checkbox checkbox) {
    _addText('Checkbox: ${checkbox.value == true ? 'aangevinkt' : 'niet aangevinkt'}');
  }

  void _addRadio(Radio radio) {
    _addText('Radio knop: ${radio.value == true ? 'geselecteerd' : 'niet geselecteerd'}');
  }

  void _addSlider(Slider slider) {
    _addText('Schuifregelaar: waarde ${slider.value}');
  }

  void _addDropdownButton(DropdownButton dropdown) {
    _addText('Dropdown menu');
  }

  void _addExpansionTile(ExpansionTile tile) {
    if (tile.title is Text) {
      _addText('Uitklapbare sectie: ${(tile.title as Text).data}');
    } else if (tile.title is RichText) {
      _addText('Uitklapbare sectie: ${(tile.title as RichText).text.toPlainText()}');
    }
    
    if (tile.subtitle is Text) {
      _addText((tile.subtitle as Text).data ?? '');
    } else if (tile.subtitle is RichText) {
      _addText((tile.subtitle as RichText).text.toPlainText());
    }
    
    if (tile.children != null) {
      for (final child in tile.children!) {
        _extractFromWidget(child);
      }
    }
  }

  void _addCheckboxListTile(CheckboxListTile tile) {
    if (tile.title is Text) {
      _addText('Checkbox: ${(tile.title as Text).data}');
    } else if (tile.title is RichText) {
      _addText('Checkbox: ${(tile.title as RichText).text.toPlainText()}');
    }
    
    if (tile.subtitle is Text) {
      _addText((tile.subtitle as Text).data ?? '');
    } else if (tile.subtitle is RichText) {
      _addText((tile.subtitle as RichText).text.toPlainText());
    }
  }

  void _addRadioListTile(RadioListTile tile) {
    if (tile.title is Text) {
      _addText('Radio: ${(tile.title as Text).data}');
    } else if (tile.title is RichText) {
      _addText('Radio: ${(tile.title as RichText).text.toPlainText()}');
    }
    
    if (tile.subtitle is Text) {
      _addText((tile.subtitle as Text).data ?? '');
    } else if (tile.subtitle is RichText) {
      _addText((tile.subtitle as RichText).text.toPlainText());
    }
  }

  void _addSwitchListTile(SwitchListTile tile) {
    if (tile.title is Text) {
      _addText('Schakelaar: ${(tile.title as Text).data}');
    } else if (tile.title is RichText) {
      _addText('Schakelaar: ${(tile.title as RichText).text.toPlainText()}');
    }
    
    if (tile.subtitle is Text) {
      _addText((tile.subtitle as Text).data ?? '');
    } else if (tile.subtitle is RichText) {
      _addText((tile.subtitle as RichText).text.toPlainText());
    }
  }

  void _addDataTable(DataTable table) {
    _addText('Tabel met ${table.rows.length} rijen');
    
    for (final row in table.rows) {
      _addDataRow(row);
    }
  }

  void _addDataRow(DataRow row) {
    for (final cell in row.cells) {
      _extractFromWidget(cell.child);
    }
  }

  void _addTable(Table table) {
    _addText('Tabel');
    
    for (final row in table.children) {
      _addTableRow(row);
    }
  }

  void _addTableRow(TableRow row) {
    for (final cell in row.children) {
      _extractFromWidget(cell);
    }
  }

  void _addStepper(Stepper stepper) {
    _addText('Stap voor stap proces met ${stepper.steps.length} stappen');
    
    for (final step in stepper.steps) {
      _addStep(step);
    }
  }

  void _addStep(Step step) {
    if (step.title is Text) {
      _addText('Stap: ${(step.title as Text).data}');
    } else if (step.title is RichText) {
      _addText('Stap: ${(step.title as RichText).text.toPlainText()}');
    }
    
    if (step.subtitle is Text) {
      _addText((step.subtitle as Text).data ?? '');
    } else if (step.subtitle is RichText) {
      _addText((step.subtitle as RichText).text.toPlainText());
    }
    
    if (step.content is Text) {
      _addText((step.content as Text).data ?? '');
    } else if (step.content is RichText) {
      _addText((step.content as RichText).text.toPlainText());
    } else if (step.content is Widget) {
      _extractFromWidget(step.content);
    }
  }
}

