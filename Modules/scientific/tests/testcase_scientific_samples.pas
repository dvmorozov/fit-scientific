// SPDX-License-Identifier: GPL-3.0-or-later
{
@abstract(The module's samples are where its manifest says, and they load.)

The diffraction profiles 1.dat to 9.dat are shipped by every package of a
product that links this module (module.json "data"), and its real-data tests
read them. The framework's own loader test no longer reads one - the framework
tree holds no data of any field - so the check that a real profile is reachable
and reads as the instrument wrote it lives here. Also the module's dialog
forms, which are read from their files because a window cannot be built
headless.
}
unit testcase_scientific_samples;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, fpcunit, testregistry, scientific_test_paths,
    dat_file_loader, title_points_set, menu_paths;

type
    TScientificSamplesTest = class(TTestCase)
    published
        procedure TheLongProfileLoadsWholeFromTheSampleFolder;
        procedure EverySampleIsThereAndHoldsPoints;
    end;

    TScientificFormFileTest = class(TTestCase)
    published
        procedure TheRolesDialogCallsSharedParametersShared;
    end;

implementation

procedure TScientificSamplesTest.TheLongProfileLoadsWholeFromTheSampleFolder;
var
    Loader: TDATFileLoader;
    PS: TTitlePointsSet;
begin
    Loader := TDATFileLoader.Create(nil);
    try
        Loader.LoadDataSet(ScientificSampleDir + '1.dat');
        PS := Loader.GetPointsSetCopy;
        try
            AssertEquals('point count', 1692, PS.PointsCount);
            AssertEquals('first X', 3.0, PS.PointXCoord[0], 1e-6);
            AssertEquals('first Y', 3377.0, PS.PointYCoord[0], 1e-6);
            AssertEquals('last X', 172.1, PS.PointXCoord[PS.PointsCount - 1], 1e-6);
            AssertEquals('last Y', 1434.0, PS.PointYCoord[PS.PointsCount - 1], 1e-6);
        finally
            PS.Free;
        end;
    finally
        Loader.Free;
    end;
end;

procedure TScientificSamplesTest.EverySampleIsThereAndHoldsPoints;
var
    Loader: TDATFileLoader;
    PS: TTitlePointsSet;
    n: longint;
begin
    for n := 1 to 9 do
    begin
        AssertTrue(IntToStr(n) + '.dat is in the sample folder',
            FileExists(ScientificSampleDir + IntToStr(n) + '.dat'));
        Loader := TDATFileLoader.Create(nil);
        try
            Loader.LoadDataSet(ScientificSampleDir + IntToStr(n) + '.dat');
            PS := Loader.GetPointsSetCopy;
            try
                AssertTrue(IntToStr(n) + '.dat holds points', PS.PointsCount > 0);
            finally
                PS.Free;
            end;
        finally
            Loader.Free;
        end;
    end;
end;

procedure TScientificFormFileTest.TheRolesDialogCallsSharedParametersShared;
var
    Caption: string;
begin
    //  THE REPORT: the list in Set Curve Type Properties was labelled "Fixed
    //  parameters", and ticking one made it SHARED - one value for every curve
    //  of an interval, which the fit still varies. Only a position ticked there
    //  is held where it is placed. The label says what ticking does.
    //  The form file is this module's, read from its repository beside the
    //  framework's (DesignedCaption names a file from the framework's root).
    Caption := DesignedCaption(
        '../fit-scientific/Desktop/ScientificForms/user_points_set_prop_dialog.lfm',
        'LabelFixedParameters');
    AssertTrue('the label is read', Caption <> '');
    AssertTrue('it says shared: ' + Caption, Pos('Shared', Caption) > 0);
    AssertTrue('and not fixed: ' + Caption, Pos('Fixed', Caption) = 0);
end;

initialization
    RegisterTest('integration', TScientificSamplesTest);
    RegisterTest('unit', TScientificFormFileTest);
end.
