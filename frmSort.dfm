object SortForm: TSortForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Advanced Sort'
  ClientHeight = 324
  ClientWidth = 589
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object lblSortOrder: TLabel
    Left = 8
    Top = 43
    Width = 57
    Height = 15
    Caption = 'Sort Order:'
  end
  object lblDirectorySort: TLabel
    Left = 8
    Top = 16
    Width = 75
    Height = 15
    Caption = 'Directory Sort:'
  end
  object lblMP3Sort: TLabel
    Left = 256
    Top = 16
    Width = 51
    Height = 15
    Caption = 'MP3 Sort:'
  end
  object sbxSortOrder: TScrollBox
    Left = 8
    Top = 64
    Width = 573
    Height = 193
    TabOrder = 0
  end
  object cbbDirectorySort: TComboBox
    Left = 89
    Top = 13
    Width = 145
    Height = 23
    Style = csDropDownList
    ItemIndex = 0
    TabOrder = 1
    Text = 'Directory First'
    Items.Strings = (
      'Directory First'
      'Files First'
      'None')
  end
  object cbbMP3FSort: TComboBox
    Left = 313
    Top = 13
    Width = 145
    Height = 23
    Style = csDropDownList
    ItemIndex = 0
    TabOrder = 2
    Text = 'Having ID3 First'
    Items.Strings = (
      'Having ID3 First'
      'Without ID3 First')
  end
  object btnAddCriteria: TButton
    Left = 8
    Top = 263
    Width = 89
    Height = 25
    Caption = 'Add Criteria'
    TabOrder = 3
    OnClick = btnAddCriteriaClick
  end
  object btnRemoveCriteria: TButton
    Left = 103
    Top = 263
    Width = 154
    Height = 25
    Caption = 'Remove Selected Criteria'
    TabOrder = 4
    OnClick = btnRemoveCriteriaClick
  end
  object btnOk: TButton
    Left = 413
    Top = 288
    Width = 75
    Height = 25
    Caption = 'OK'
    TabOrder = 5
    OnClick = btnOkClick
  end
  object btnCancel: TButton
    Left = 494
    Top = 288
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 6
  end
end
