{ Global compiler directives }
{$include bold.inc}
unit BoldSelectionListHandle;

interface

uses
  BoldSystemRT,
  BoldSystem,
  BoldElements,
  BoldRootedHandles,
  BoldAbstractListHandle,
  BoldCursorHandle;

type
  { forward declarations }
  TBoldSelectionListHandle  = class;
  TBoldMultiSelectionListHandle  = class;

  { TBoldSelectionListHandle }
  TBoldSelectionListHandle = class(TBoldAbstractListHandle)
  private
    function GetCount: Integer;
    function GetCurrentBoldObject: TBoldObject;
    function GetListElementType: TBoldElementTypeInfo;
    function GetHasNext: Boolean;
    function GetHasPrior: Boolean;
    function GetListType: TBoldListTypeInfo;
    function GetStaticListType: TBoldListTypeInfo;
    function GetObjectList: TBoldObjectList;
    function GetMutableObjectList: TBoldObjectList;
    procedure SetCurrentBoldObject(const Value: TBoldObject);
    procedure SetCurrentElement(const Value: TBoldElement);
  protected
    function GetCurrentElement: TBoldElement; virtual; abstract;
    function GetCurrentIndex: Integer; virtual; abstract;
    function GetList: TBoldList; virtual; abstract;
    procedure SetCurrentIndex(Value: Integer); virtual; abstract;
    function GetMutableList: TBoldList; virtual;
  public
{
    procedure First;
    procedure Last;
    procedure Next;
    procedure Prior;
    procedure RemoveCurrentElement;
    property Count: Integer read GetCount;
    property CurrentBoldObject: TBoldObject read GetCurrentBoldObject write SetCurrentBoldObject;
    property CurrentElement: TBoldElement read GetCurrentElement write SetCurrentElement;
    property CurrentIndex: Integer read GetCurrentIndex write SetCurrentIndex;
    property List: TBoldList read GetList;
    property ObjectList: TBoldObjectList read GetObjectList;
    property ListElementType: TBoldElementTypeInfo read GetListElementType;
    property ListType: TBoldListTypeInfo read GetListType;
    property StaticListType: TBoldListTypeInfo read GetStaticListType;
    property HasNext: Boolean read GetHasNext;
    property HasPrior: Boolean read GetHasPrior;
    property MutableList: TBoldList read GetMutableList;
    property MutableObjectList: TBoldObjectList read GetMutableObjectList;
}
  end;

  { TBoldSelectionListHandle }
  TBoldSelectionListHandle = class(TBoldAbstractListHandle)
  private
    function GetCount: Integer;
    function GetCurrentBoldObject: TBoldObject;
    function GetListElementType: TBoldElementTypeInfo;
    function GetHasNext: Boolean;
    function GetHasPrior: Boolean;
    function GetListType: TBoldListTypeInfo;
    function GetStaticListType: TBoldListTypeInfo;
    function GetObjectList: TBoldObjectList;
    function GetMutableObjectList: TBoldObjectList;
    procedure SetCurrentBoldObject(const Value: TBoldObject);
    procedure SetCurrentElement(const Value: TBoldElement);
  protected
    function GetCurrentElement: TBoldElement; virtual; abstract;
    function GetCurrentIndex: Integer; virtual; abstract;
    function GetList: TBoldList; virtual; abstract;
    procedure SetCurrentIndex(Value: Integer); virtual; abstract;
    function GetMutableList: TBoldList; virtual;
  public
  end;
implementation

uses
  SysUtils,

  BoldCoreConsts,
  BoldDefs;

end.

