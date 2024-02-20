object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'MainForm'
  ClientHeight = 647
  ClientWidth = 1038
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    1038
    647)
  PixelsPerInch = 96
  TextHeight = 13
  object btnRefreshDriveList: TButton
    Left = 239
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Refresh'
    TabOrder = 0
    OnClick = btnRefreshDriveListClick
  end
  object cbbDriveList: TComboBox
    Left = 8
    Top = 8
    Width = 225
    Height = 22
    Style = csOwnerDrawFixed
    TabOrder = 1
    OnChange = cbbDriveListChange
    OnDrawItem = cbbDriveListDrawItem
  end
  object lvFolderList: TListView
    Left = 8
    Top = 39
    Width = 1022
    Height = 569
    Anchors = [akLeft, akTop, akRight, akBottom]
    Columns = <
      item
        AutoSize = True
        Caption = 'Name'
      end
      item
        Caption = 'Date Modified'
        Width = 150
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
    TabOrder = 2
    ViewStyle = vsReport
    OnData = lvFolderListData
    OnDblClick = lvFolderListDblClick
    OnDragDrop = lvFolderListDragDrop
    OnDragOver = lvFolderListDragOver
    ExplicitWidth = 894
  end
  object btnSort: TButton
    Left = 703
    Top = 8
    Width = 66
    Height = 25
    Caption = 'Sort'
    TabOrder = 3
    OnClick = btnSortClick
  end
  object cbbSortFuncList: TComboBox
    Left = 360
    Top = 8
    Width = 337
    Height = 21
    Style = csDropDownList
    TabOrder = 4
  end
  object Button1: TButton
    Left = 8
    Top = 614
    Width = 97
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Write to Disk'
    TabOrder = 5
    OnClick = Button1Click
  end
end
