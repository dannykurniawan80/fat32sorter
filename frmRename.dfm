object RenameForm: TRenameForm
  Left = 0
  Top = 0
  Caption = 'Rename'
  ClientHeight = 561
  ClientWidth = 784
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    784
    561)
  TextHeight = 15
  object gbOptions: TGroupBox
    Left = 8
    Top = 8
    Width = 609
    Height = 97
    Caption = ' Options '
    TabOrder = 0
    object lblFileName: TLabel
      Left = 16
      Top = 24
      Width = 56
      Height = 15
      Caption = 'File Name:'
      FocusControl = cbbFileName
    end
    object cbbFileName: TComboBox
      Left = 78
      Top = 21
      Width = 195
      Height = 23
      Style = csDropDownList
      TabOrder = 0
      OnChange = cbbFileNameChange
    end
    object cbRenameDirs: TCheckBox
      Left = 288
      Top = 21
      Width = 137
      Height = 17
      Caption = 'Also rename folders'
      TabOrder = 2
      OnClick = cbRenameDirsClick
    end
    object cbDifferentDirAndFileNumbers: TCheckBox
      Left = 288
      Top = 44
      Width = 225
      Height = 17
      Caption = 'Differentiate file and folder numbers'
      Checked = True
      Enabled = False
      State = cbChecked
      TabOrder = 3
    end
    object btnPreview: TButton
      Left = 519
      Top = 32
      Width = 75
      Height = 25
      Caption = 'Preview'
      TabOrder = 6
      OnClick = btnPreviewClick
    end
    object cbRemovePrefix: TCheckBox
      Left = 78
      Top = 50
      Width = 179
      Height = 17
      Caption = 'Remove existing prefix first'
      TabOrder = 1
    end
    object btnReset: TButton
      Left = 519
      Top = 63
      Width = 75
      Height = 25
      Caption = 'Reset'
      TabOrder = 7
      OnClick = btnResetClick
    end
    object cbDigits: TCheckBox
      Left = 288
      Top = 67
      Width = 59
      Height = 17
      Caption = 'Digits:'
      TabOrder = 4
      OnClick = cbDigitsClick
    end
    object spDigits: TSpinEdit
      Left = 353
      Top = 64
      Width = 56
      Height = 24
      Enabled = False
      MaxValue = 0
      MinValue = 1
      TabOrder = 5
      Value = 0
    end
  end
  object lvFolderList: TListView
    Left = 8
    Top = 111
    Width = 768
    Height = 441
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
    FullDrag = True
    GridLines = True
    HideSelection = False
    MultiSelect = True
    OwnerData = True
    ReadOnly = True
    RowSelect = True
    TabOrder = 3
    ViewStyle = vsReport
    OnData = lvFolderListData
  end
  object btnApply: TButton
    Left = 637
    Top = 48
    Width = 75
    Height = 25
    Caption = 'Apply'
    TabOrder = 1
    OnClick = btnApplyClick
  end
  object btnCancel: TButton
    Left = 637
    Top = 79
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
