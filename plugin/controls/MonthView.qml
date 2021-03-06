// Copyright (C) 2018 Michael Bohlender, <bohlender@kolabsys.com>
// Copyright (C) 2018 Christian Mollekopf, <mollekopf@kolabsys.com>
// SPDX-FileCopyrightText: 2021 Claudio Cambra <claudio.cambra@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.4
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.15 as QQC2

import org.mauikit.controls 1.3 as Maui
import org.maui.calendar 1.0 as Kalendar

import "dateutils.js" as DateUtils

Maui.Page
{
    id: monthPage

    padding : 0

    property date currentDate: new Date()
    Timer
    {
        interval: 5000;
        running: true
        repeat: true
        onTriggered: currentDate = new Date()
    }

    property var openOccurrence: ({})
    property var filter: {
        "collectionId": -1,
        "tags": [],
        "name": ""
    }

    property alias model :  _monthViewModel
    property date startDate
    property date firstDayOfMonth
    property int month
    property int year
    property bool initialMonth: true
    readonly property bool isLarge: width > Maui.Style.units.gridUnit * 40
    readonly property bool isTiny: width < Maui.Style.units.gridUnit * 18

    property date selectedDate : currentDate

    property bool dragDropEnabled: true

    background: Rectangle
    {
        color: Maui.Theme.backgroundColor
    }

    Kalendar.InfiniteCalendarViewModel
    {
        id: _monthViewModel
        scale: Kalendar.InfiniteCalendarViewModel.MonthScale
        //        calendar: CalendarManager.calendar
        //        filter: root.filter
    }


    function setToDate(date, isInitialMonth = false)
    {
        monthPage.initialMonth = isInitialMonth;
        let monthDiff = date.getMonth() - pathView.currentItem.firstDayOfMonth.getMonth() + (12 * (date.getFullYear() - pathView.currentItem.firstDayOfMonth.getFullYear()))
        let newIndex = pathView.currentIndex + monthDiff;

        let firstItemDate = pathView.model.data(pathView.model.index(1,0), Kalendar.InfiniteCalendarViewModel.FirstDayOfMonthRole);
        let lastItemDate = pathView.model.data(pathView.model.index(pathView.model.rowCount() - 1,0), Kalendar.InfiniteCalendarViewModel.FirstDayOfMonthRole);

        while(firstItemDate >= date) {
            pathView.model.addDates(false)
            firstItemDate = pathView.model.data(pathView.model.index(1,0), Kalendar.InfiniteCalendarViewModel.FirstDayOfMonthRole);
            newIndex = 0;
        }
        if(firstItemDate < date && newIndex === 0) {
            newIndex = date.getMonth() - firstItemDate.getMonth() + (12 * (date.getFullYear() - firstItemDate.getFullYear())) + 1;
        }

        while(lastItemDate <= date) {
            pathView.model.addDates(true)
            lastItemDate = pathView.model.data(pathView.model.index(pathView.model.rowCount() - 1,0), Kalendar.InfiniteCalendarViewModel.FirstDayOfMonthRole);
        }
        pathView.currentIndex = newIndex;
    }

    headBar.background: null
    title: Qt.formatDate(pathView.currentItem.startDate, "MMM yyyy")

    headBar.leftContent: Maui.ToolActions
    {
        autoExclusive: false
        checkable: false

        QQC2.Action
        {
            icon.name: "go-previous"
            text: i18n("Previous Month")
            shortcut: "Left"
            onTriggered: setToDate(DateUtils.addMonthsToDate(pathView.currentItem.firstDayOfMonth, -1))
        }
        QQC2.Action
        {
            icon.name: "go-jump-today"
            text: i18n("Today")
            onTriggered: setToDate(new Date())
        }
        QQC2.Action
        {
            icon.name: "go-next"
            text: i18n("Next Month")
            shortcut: "Right"
            onTriggered: setToDate(DateUtils.addMonthsToDate(pathView.currentItem.firstDayOfMonth, 1))
        }
    }


    PathView
    {
        id: pathView

        anchors.fill: parent
        flickDeceleration: Maui.Style.units.longDuration
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        //        spacing: 10
        snapMode: PathView.SnapToItem
        focus: true
        //        interactive: Kirigami.Settings.tabletMode

        path: Path {
            startX: - pathView.width * pathView.count / 2 + pathView.width / 2
            startY: pathView.height / 2
            PathLine {
                x: pathView.width * pathView.count / 2 + pathView.width / 2
                y: pathView.height / 2
            }
        }

        model: monthPage.model

        property int startIndex

        Component.onCompleted:
        {
            startIndex = count / 2;
            currentIndex = startIndex;
        }

        onCurrentIndexChanged:
        {
            monthPage.startDate = currentItem.startDate;
            monthPage.firstDayOfMonth = currentItem.firstDayOfMonth;
            monthPage.month = currentItem.month;
            monthPage.year = currentItem.year;

            if(currentIndex >= count - 2) {
                model.addDates(true);
            } else if (currentIndex <= 1) {
                model.addDates(false);
                startIndex += model.datesToAdd;
            }
        }

        delegate: Loader
        {
            id: viewLoader

            property date startDate: model.startDate
            property date firstDayOfMonth: model.firstDay
            property int month: model.selectedMonth - 1 // Convert QDateTime month to JS month
            property int year: model.selectedYear

            property bool isNextOrCurrentItem: index >= pathView.currentIndex -1 && index <= pathView.currentIndex + 1
            property bool isCurrentItem: PathView.isCurrentItem

            active: isNextOrCurrentItem
            asynchronous: !isCurrentItem
            visible: status === Loader.Ready

            sourceComponent: Kalendar.DayGridView
            {
                id: dayView
                objectName: "monthView"

                width: pathView.width
                height: pathView.height

                //                model: monthViewModel // from monthPage model
                isCurrentView: viewLoader.isCurrentItem
                dragDropEnabled: monthPage.dragDropEnabled

                startDate: viewLoader.startDate
                currentDate: monthPage.currentDate
                month: viewLoader.month

                onDateClicked: monthPage.selectedDate = date

                dayHeaderDelegate: QQC2.Control
                {
                    leftPadding: Maui.Style.units.smallSpacing
                    rightPadding: Maui.Style.units.smallSpacing

                    contentItem: Maui.LabelDelegate
                    {
                        label:
                        {
                            let longText = day.toLocaleString(Qt.locale(), "dddd");
                            let midText = day.toLocaleString(Qt.locale(), "ddd");
                            let shortText = midText.slice(0,1);


                            return monthPage.isTiny ? shortText : midText;
                        }


                        labelTxt.horizontalAlignment: Text.AlignRight
                        labelTxt.font.bold: true
                        labelTxt.font.weight: Font.Bold
                        labelTxt.font.pointSize: Maui.Style.fontSizes.big

                    }
                }

                weekHeaderDelegate: Maui.LabelDelegate
                {
                    padding: Maui.Style.units.smallSpacing
                    //                                        verticalAlignment: Qt.AlignTop
                    labelTxt.horizontalAlignment: Qt.AlignHCenter
                    label: DateUtils.getWeek(startDate, Qt.locale().firstDayOfWeek)
                    //                    background: Rectangle {
                    //                        Kirigami.Theme.inherit: false
                    //                        Kirigami.Theme.colorSet: Kirigami.Theme.View
                    //                        color: Kirigami.Theme.backgroundColor
                    //                    }
                }

                openOccurrence: monthPage.openOccurrence
            }
        }
    }
}

