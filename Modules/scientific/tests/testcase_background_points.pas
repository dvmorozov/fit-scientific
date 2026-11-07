// SPDX-License-Identifier: GPL-3.0-or-later
{
@abstract(The background points: selected by hand or by an algorithm, or the
values of the model's background curve - never both at once.)

THE BACKGROUND IS ONE OF TWO THINGS (decided with the user, 2026-11-07). A
model curve is fitted with the peaks on the data outside the fit intervals; a
set of selected points is only interpolated and subtracted
(Model > Background > Subtract) and never fitted. The Background Points table
shows whichever there is: the points that were selected, or, while a curve is
the background, the curve's values at every sample of the profile - which the
server computes from the curve each time they are asked for, as it does the
points of every other curve, so they cannot disagree with it and are not
saved. None is a choice again, because selected points need a model with no
curve.

Every test enters where the application enters: the REST router the compute
server runs.
}
unit testcase_background_points;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils, fpcunit, testregistry, fpjson,
    fit_points_json, points_set, testcase_background_model,
    gauss_points_set, polynomial_background_points_set,
    chebyshev_background_points_set, pseudo_voigt_points_set;

type
    TBackgroundPointsRestTest = class(TBackgroundRestBase)
    private
        function BackgroundRouteOf(AId: longint): TPointsData;
        function Send(const AMethod, APath, ABody: string;
            out AMessage: string): longint;
        function PutPoints(AId: longint; const ABody: string;
            out AMessage: string): longint;
        { Model > Background > Curve > None. }
        procedure ChooseNone(AId: longint);
    published
        { THE CURVE'S VALUES, as the table shows them. }
        procedure WithACurveTheRouteListsItsValuesAtEverySample;
        procedure TheValuesFollowAnEditOfTheCurve;
        { NONE IS A CHOICE AGAIN. }
        procedure NoneIsAcceptedAndLeavesNoBackgroundPoints;
        procedure NoneSurvivesAChangeOfThePeakType;
        procedure DeletingTheBackgroundCurveLeavesNone;
        { A CURVE AND SELECTED POINTS EXCLUDE EACH OTHER. }
        procedure PointsCanBeSelectedWhenNoCurveIsTheBackground;
        procedure PointsAreRefusedWhileACurveIsTheBackground;
        procedure ACurveIsRefusedWhileSelectedPointsExist;
        { THE CURVE'S POINTS GO ONLY WITH THE CURVE. }
        procedure TheCurvesPointsCannotBeDeletedOrCleared;
    end;

implementation

const
    TheCurve = 'curve';

function TBackgroundPointsRestTest.BackgroundRouteOf(AId: longint): TPointsData;
var
    Code: longint;
    Body: string;
begin
    FApi.Handle('GET', Format('/problems/%d/background', [AId]), '', Code, Body);
    AssertEquals('the background is readable', 200, Code);
    AssertTrue('and decodes', PointsFromJsonString(Body, Result));
end;

function TBackgroundPointsRestTest.Send(const AMethod, APath, ABody: string;
    out AMessage: string): longint;
var
    R: TJSONObject;
begin
    AMessage := '';
    R := Call(AMethod, APath, ABody, Result);
    try
        if Assigned(R) then
            AMessage := R.Get('error', R.Get('message', ''));
    finally
        R.Free;
    end;
end;

function TBackgroundPointsRestTest.PutPoints(AId: longint; const ABody: string;
    out AMessage: string): longint;
begin
    Result := Send('PUT', Format('/problems/%d/background', [AId]), ABody,
        AMessage);
end;

procedure TBackgroundPointsRestTest.ChooseNone(AId: longint);
var
    Msg: string;
begin
    AssertEquals('None is accepted', 200,
        PutSettings(AId, '{"backgroundCurveType":""}', Msg));
end;

procedure TBackgroundPointsRestTest.WithACurveTheRouteListsItsValuesAtEverySample;
var
    Id, i: longint;
    Listed, Drawn: TPointsData;
begin
    //  THE DEFECT: a new model of peaks has a background curve and its
    //  points set is empty, so the table said there was no background.
    Id := BackgroundProblem;
    Listed := BackgroundRouteOf(Id);
    Drawn := PointsOfType(Id, TChebyshevBackgroundPointsSet.GetCurveTypeId);
    AssertTrue('there are values', Length(Listed.X) > 2);
    AssertEquals('one per sample of the curve as it is drawn',
        Length(Drawn.X), Length(Listed.X));
    for i := 0 to High(Drawn.X) do
    begin
        AssertEquals('abscissa ' + IntToStr(i), Drawn.X[i], Listed.X[i], 1E-12);
        AssertEquals('value ' + IntToStr(i), Drawn.Y[i], Listed.Y[i], 1E-9);
    end;
end;

procedure TBackgroundPointsRestTest.TheValuesFollowAnEditOfTheCurve;
var
    Id, Code: longint;
    Before, After, Drawn: TPointsData;
begin
    Id := BackgroundProblem;
    ChooseBackground(Id, TLinearBackgroundPointsSet.GetCurveTypeId);
    Before := BackgroundRouteOf(Id);
    Code := PutParamOfType(Id, TLinearBackgroundPointsSet.GetCurveTypeId,
        'b0', ParamOfType(Id, TLinearBackgroundPointsSet.GetCurveTypeId, 'b0')
        + 50);
    AssertEquals('the edit is accepted', 200, Code);
    After := BackgroundRouteOf(Id);
    Drawn := PointsOfType(Id, TLinearBackgroundPointsSet.GetCurveTypeId);
    AssertEquals(Length(Drawn.Y), Length(After.Y));
    AssertTrue('the values moved with the curve',
        Abs(After.Y[0] - Before.Y[0]) > 1);
    AssertEquals('and are the curve''s', Drawn.Y[0], After.Y[0], 1E-9);
end;

procedure TBackgroundPointsRestTest.NoneIsAcceptedAndLeavesNoBackgroundPoints;
var
    Id: longint;
    S: TJSONObject;
begin
    Id := BackgroundProblem;
    ChooseNone(Id);
    S := SettingsOf(Id);
    try
        AssertEquals('no background type', '', S.Get('backgroundCurveType', 'x'));
    finally
        S.Free;
    end;
    AssertEquals('only the peak is left', 1, CurveCount(Id));
    AssertEquals('and no points', 0, Length(BackgroundRouteOf(Id).X));
end;

procedure TBackgroundPointsRestTest.NoneSurvivesAChangeOfThePeakType;
var
    Id: longint;
    Msg: string;
    S: TJSONObject;
begin
    //  The engine used to give a model of peaks its default background back
    //  whenever the peak type was set; with None chosen that undoes the choice.
    Id := BackgroundProblem;
    ChooseNone(Id);
    AssertEquals('another peak type is accepted', 200, PutSettings(Id,
        Format('{"curveType":"%s"}',
        [GUIDToString(TPseudoVoigtPointsSet.GetCurveTypeId)]), Msg));
    S := SettingsOf(Id);
    try
        AssertEquals('still none', '', S.Get('backgroundCurveType', 'x'));
    finally
        S.Free;
    end;
end;

procedure TBackgroundPointsRestTest.DeletingTheBackgroundCurveLeavesNone;
var
    Id: longint;
    Msg: string;
    S: TJSONObject;
begin
    Id := BackgroundProblem;
    AssertEquals('the curve''s row is deleted', 200, Send('DELETE',
        Format('/problems/%d/points/positions/%s',
        [Id, HandleOfType(Id, TChebyshevBackgroundPointsSet.GetCurveTypeId)]),
        '', Msg));
    S := SettingsOf(Id);
    try
        AssertEquals('none', '', S.Get('backgroundCurveType', 'x'));
    finally
        S.Free;
    end;
    AssertEquals('and the peak stays', 1, CurveCount(Id));
end;

procedure TBackgroundPointsRestTest.PointsCanBeSelectedWhenNoCurveIsTheBackground;
var
    Id: longint;
    Msg: string;
    Got: TPointsData;
begin
    Id := BackgroundProblem;
    ChooseNone(Id);
    AssertEquals('a point is picked', 200, Send('POST',
        Format('/problems/%d/points/background', [Id]), '{"x":2,"y":3}', Msg));
    AssertEquals('and a set is put', 200, PutPoints(Id,
        '{"x":[1,5,9],"y":[2,2,2]}', Msg));
    Got := BackgroundRouteOf(Id);
    AssertEquals('they are the set', 3, Length(Got.X));
    AssertEquals(5, Got.X[1], 1E-12);
end;

procedure TBackgroundPointsRestTest.PointsAreRefusedWhileACurveIsTheBackground;
var
    Id: longint;
    Msg: string;
    Before: TPointsData;
begin
    Id := BackgroundProblem;
    Before := BackgroundRouteOf(Id);
    AssertTrue('a set is refused', PutPoints(Id, '{"x":[1,5],"y":[2,2]}', Msg)
        >= 400);
    AssertTrue('and the refusal names the curve: ' + Msg,
        Pos(TheCurve, LowerCase(Msg)) > 0);
    AssertTrue('a pick is refused', Send('POST',
        Format('/problems/%d/points/background', [Id]), '{"x":2,"y":3}', Msg)
        >= 400);
    AssertTrue('and so is computing points: ' + Msg, Send('POST',
        Format('/problems/%d/actions/compute-background-points', [Id]), '', Msg)
        >= 400);
    AssertTrue('and the refusal names the curve: ' + Msg,
        Pos(TheCurve, LowerCase(Msg)) > 0);
    AssertEquals('nothing changed', Length(Before.X),
        Length(BackgroundRouteOf(Id).X));
end;

procedure TBackgroundPointsRestTest.ACurveIsRefusedWhileSelectedPointsExist;
var
    Id: longint;
    Msg: string;
    S: TJSONObject;
begin
    Id := BackgroundProblem;
    ChooseNone(Id);
    AssertEquals(200, PutPoints(Id, '{"x":[1,5,9],"y":[2,2,2]}', Msg));
    AssertTrue('refused', PutSettings(Id, Format('{"backgroundCurveType":"%s"}',
        [GUIDToString(TLinearBackgroundPointsSet.GetCurveTypeId)]), Msg) >= 400);
    AssertTrue('and it says to clear the points: ' + Msg,
        Pos('points', LowerCase(Msg)) > 0);
    AssertEquals('the points are still there', 3, Length(BackgroundRouteOf(Id).X));
    S := SettingsOf(Id);
    try
        AssertEquals('and the model still has none', '',
            S.Get('backgroundCurveType', 'x'));
    finally
        S.Free;
    end;
end;

procedure TBackgroundPointsRestTest.TheCurvesPointsCannotBeDeletedOrCleared;
var
    Id, Count: longint;
    Msg: string;
    First: TPointsData;
begin
    Id := BackgroundProblem;
    First := BackgroundRouteOf(Id);
    Count := Length(First.X);
    AssertTrue('one point', Send('DELETE', Format(
        '/problems/%d/points/background/%s', [Id, FloatToStr(First.X[0])]), '',
        Msg) >= 400);
    AssertTrue('and the refusal says they are the curve''s: ' + Msg,
        Pos('model', LowerCase(Msg)) > 0);
    AssertTrue('all of them', PutPoints(Id, '{"x":[],"y":[]}', Msg) >= 400);
    AssertEquals('every value is still there', Count,
        Length(BackgroundRouteOf(Id).X));
end;

initialization
    RegisterTest('unit', TBackgroundPointsRestTest);

end.
