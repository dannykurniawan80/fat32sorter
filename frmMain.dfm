object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'MainForm'
  ClientHeight = 661
  ClientWidth = 984
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    984
    661)
  TextHeight = 13
  object lblDrive: TLabel
    Left = 8
    Top = 19
    Width = 29
    Height = 13
    Caption = 'Drive:'
  end
  object lblSort: TLabel
    Left = 472
    Top = 19
    Width = 24
    Height = 13
    Caption = 'Sort:'
    FocusControl = cbbQuickSortList
  end
  object lblNote: TLabel
    Left = 207
    Top = 628
    Width = 289
    Height = 13
    Caption = 'NOTE: Drag && drop files or folders to arrange them manually'
  end
  object btnRefreshDriveList: TButton
    Left = 355
    Top = 14
    Width = 75
    Height = 25
    Caption = 'Refresh'
    TabOrder = 2
    OnClick = btnRefreshDriveListClick
  end
  object cbbDriveList: TComboBox
    Left = 43
    Top = 16
    Width = 225
    Height = 22
    Style = csOwnerDrawFixed
    TabOrder = 0
    OnChange = cbbDriveListChange
    OnDrawItem = cbbDriveListDrawItem
  end
  object lvFolderList: TListView
    Left = 8
    Top = 56
    Width = 968
    Height = 566
    Anchors = [akLeft, akTop, akRight, akBottom]
    Columns = <
      item
        Caption = 'Name'
        Width = 250
      end
      item
        Caption = 'Date Modified'
        Width = 120
      end
      item
        Caption = 'Created Date'
        Width = 120
      end
      item
        Caption = 'Type'
        Width = 100
      end
      item
        Caption = 'Size'
        Width = 75
      end
      item
        Caption = 'Track#'
      end
      item
        Caption = 'Album'
        Width = 100
      end
      item
        Caption = 'Artist'
        Width = 100
      end
      item
        Caption = 'Title'
        Width = 150
      end
      item
        Caption = 'Year'
      end
      item
        Caption = 'Disc#'
      end>
    DragMode = dmAutomatic
    FullDrag = True
    GridLines = True
    HideSelection = False
    MultiSelect = True
    OwnerData = True
    ReadOnly = True
    RowSelect = True
    SmallImages = SharedDataModule.imglstSmallIcons
    TabOrder = 6
    ViewStyle = vsReport
    OnData = lvFolderListData
    OnDblClick = lvFolderListDblClick
    OnDragDrop = lvFolderListDragDrop
    OnDragOver = lvFolderListDragOver
  end
  object btnSort: TButton
    Left = 735
    Top = 14
    Width = 74
    Height = 25
    Caption = '&Sort'
    DropDownMenu = pmSort
    Style = bsSplitButton
    TabOrder = 4
    OnClick = btnSortClick
  end
  object cbbQuickSortList: TComboBox
    Left = 502
    Top = 16
    Width = 227
    Height = 21
    Style = csDropDownList
    TabOrder = 3
  end
  object btnWriteToDisk: TButton
    Left = 89
    Top = 628
    Width = 97
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Write to Disk'
    Enabled = False
    TabOrder = 8
    OnClick = btnWriteToDiskClick
  end
  object btnOpenCloseDrive: TButton
    Left = 274
    Top = 14
    Width = 75
    Height = 25
    Caption = '&Open'
    Enabled = False
    TabOrder = 1
    OnClick = btnOpenCloseDriveClick
  end
  object btnRename: TButton
    Left = 839
    Top = 14
    Width = 106
    Height = 25
    Caption = 'Rename Files...'
    TabOrder = 5
    OnClick = btnRenameClick
  end
  object btnReload: TButton
    Left = 8
    Top = 628
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Reload'
    TabOrder = 7
    OnClick = btnReloadClick
  end
  object btnQuit: TButton
    Left = 901
    Top = 628
    Width = 75
    Height = 25
    Caption = '&Quit'
    TabOrder = 9
    OnClick = btnQuitClick
  end
  object pmSort: TPopupMenu
    Left = 776
    Top = 48
    object AdvancedSort1: TMenuItem
      Caption = '&Advanced Sort...'
      OnClick = AdvancedSort1Click
    end
  end
end
