{ ============================================================================
    File Name   : dmShared.pas
    Author      : Danny Kurniawan <danny.kurniawan@gmail.com>
    Description : Data Module for shared components
    License     : GPLv3
  ============================================================================ }
unit dmShared;

interface

uses
  System.SysUtils, System.Classes, System.ImageList, Vcl.ImgList, Vcl.Controls;

type
  TSharedDataModule = class(TDataModule)
    imglstSmallIcons: TImageList;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  SharedDataModule: TSharedDataModule;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

end.
