import UM 1.2 as UM
import Cura 1.0 as Cura

import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Layouts 1.1
import QtQuick.Window 2.1

Cura.MachineAction
{
    id: base
    anchors.fill: parent;
    property var selectedInstance: null
    Column
    {
        anchors.fill: parent;
        id: discoverWirelessPrintAction

        spacing: UM.Theme.getSize("default_margin").height

        SystemPalette { id: palette }
        UM.I18nCatalog { id: catalog; name:"cura" }
        Label
        {
            id: pageTitle
            width: parent.width
            text: catalog.i18nc("@title", "Connect to Networked Printer")
            wrapMode: Text.WordWrap
            font.pointSize: 18
        }

/*
        Image {
            id: image
            source: "WirelessPrinting.png"
        }
*/

        Label
        {
            id: pageDescription
            width: parent.width
            wrapMode: Text.WordWrap
            text: catalog.i18nc("@label", "To print directly to your printer over the network, please make sure your printer is connected to the network using a network cable or by connecting your printer to your WIFI network. If you don't connect Cura with your printer, you can still use a USB drive to transfer g-code files to your printer.\n\nSelect your printer from the list below:")
        }

        Row
        {
            spacing: UM.Theme.getSize("default_lining").width

            Button
            {
                id: addButton
                text: catalog.i18nc("@action:button", "Add");
                onClicked:
                {
                    manualPrinterDialog.showDialog("", "", "80", "/", false);
                }
            }

            Button
            {
                id: editButton
                text: catalog.i18nc("@action:button", "Edit")
                enabled: base.selectedInstance != null && base.selectedInstance.getProperty("manual") == "true"
                onClicked:
                {
                    manualPrinterDialog.showDialog(base.selectedInstance.name, base.selectedInstance.ipAddress,
                                                   base.selectedInstance.port, base.selectedInstance.path,
                                                   base.selectedInstance.getProperty("useHttps") == "true");
                }
            }

            Button
            {
                id: removeButton
                text: catalog.i18nc("@action:button", "Remove")
                enabled: base.selectedInstance != null && base.selectedInstance.getProperty("manual") == "true"
                onClicked: manager.removeManualInstance(base.selectedInstance.name)
            }

            Button
            {
                id: rediscoverButton
                text: catalog.i18nc("@action:button", "Refresh")
                onClicked: manager.startDiscovery()
            }
        }

        Row
        {
            width: parent.width
            spacing: UM.Theme.getSize("default_margin").width
            ScrollView
            {
                id: objectListContainer
                frameVisible: true
                width: parent.width * 0.5
                height: base.height - parent.y

                Rectangle
                {
                    parent: viewport
                    anchors.fill: parent
                    color: palette.light
                }

                ListView
                {
                    id: listview
                    model: manager.discoveredInstances
                    onModelChanged:
                    {
                        var selectedKey = manager.getStoredKey();
                        for(var i = 0; i < model.length; i++) {
                            if(model[i].getKey() == selectedKey)
                            {
                                currentIndex = i;
                                return
                            }
                        }
                        currentIndex = -1;
                    }
                    width: parent.width
                    currentIndex: activeIndex
                    onCurrentIndexChanged: base.selectedInstance = listview.model[currentIndex]
                    Component.onCompleted: manager.startDiscovery()
                    delegate: Rectangle
                    {
                        height: childrenRect.height
                        color: ListView.isCurrentItem ? palette.highlight : index % 2 ? palette.base : palette.alternateBase
                        width: parent.width
                        Label
                        {
                            anchors.left: parent.left
                            anchors.leftMargin: UM.Theme.getSize("default_margin").width
                            anchors.right: parent.right
                            text: listview.model[index].name
                            color: parent.ListView.isCurrentItem ? palette.highlightedText : palette.text
                            elide: Text.ElideRight
                        }

                        MouseArea
                        {
                            anchors.fill: parent;
                            onClicked:
                            {
                                if(!parent.ListView.isCurrentItem)
                                {
                                    parent.ListView.view.currentIndex = index;
                                }
                            }
                        }
                    }
                }
            }
            Column
            {
                width: parent.width * 0.5
                spacing: UM.Theme.getSize("default_margin").height
                Label
                {
                    visible: base.selectedInstance != null
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: base.selectedInstance ? base.selectedInstance.name : ""
                    font.pointSize: 16
                    elide: Text.ElideRight
                }
                Grid
                {
                    visible: base.selectedInstance != null
                    width: parent.width
                    columns: 2
                    rowSpacing: UM.Theme.getSize("default_lining").height
                    Label
                    {
                        width: parent.width * 0.2
                        wrapMode: Text.WordWrap
                        text: catalog.i18nc("@label", "Version")
                    }
                    Label
                    {
                        width: parent.width * 0.75
                        wrapMode: Text.WordWrap
                        text: base.selectedInstance ? base.selectedInstance.wirelessprintVersion : ""
                    }
                    Label
                    {
                        width: parent.width * 0.2
                        wrapMode: Text.WordWrap
                        text: catalog.i18nc("@label", "Address")
                    }
                    Label
                    {
                        width: parent.width * 0.7
                        wrapMode: Text.WordWrap
                        text: base.selectedInstance ? "%1:%2".arg(base.selectedInstance.ipAddress).arg(String(base.selectedInstance.port)) : ""
                    }
                }

                Column
                {
                    visible: base.selectedInstance != null
                    width: parent.width
                    spacing: UM.Theme.getSize("default_lining").height
                }

                Flow
                {
                    visible: base.selectedInstance != null
                    spacing: UM.Theme.getSize("default_margin").width

                    Button
                    {
                        text: catalog.i18nc("@action", "Open in browser...")
                        onClicked: manager.openWebPage(base.selectedInstance.baseURL)
                    }

                    Button
                    {
                        text: catalog.i18nc("@action:button", "Connect")
                        onClicked:
                        {
                            manager.setKey(base.selectedInstance.getKey())
                            completed()
                        }
                    }
                }

                Label
                {
                    text: catalog.i18nc("@label", "Note: Printing UltiGCode using WirelessPrint does not work. Please switch your Gcode flavour to RepRap (Marlin/Sprinter).")
                    width: parent.width - UM.Theme.getSize("default_margin").width
                    wrapMode: Text.WordWrap
                    visible: machineGCodeFlavorProvider.properties.value == "UltiGCode"
                }
            }
        }
    }

    UM.SettingPropertyProvider
    {
        id: machineGCodeFlavorProvider

        containerStackId: Cura.MachineManager.activeMachineId
        key: "machine_gcode_flavor"
        watchedProperties: [ "value" ]
        storeIndex: 4
    }

    UM.Dialog
    {
        id: manualPrinterDialog
        property string oldName
        property alias nameText: nameField.text
        property alias addressText: addressField.text
        property alias portText: portField.text
        property alias pathText: pathField.text

        title: catalog.i18nc("@title:window", "Manually added WirelessPrint instance")

        minimumWidth: 400 * Screen.devicePixelRatio
        minimumHeight: 140 * Screen.devicePixelRatio
        width: minimumWidth
        height: minimumHeight

        signal showDialog(string name, string address, string port, string path_, bool useHttps)
        onShowDialog:
        {
            oldName = name;
            nameText = name;
            nameField.selectAll();
            nameField.focus = true;

            addressText = address;
            portText = port;
            pathText = path_;
            httpsCheckbox.checked = useHttps;

            manualPrinterDialog.show();
        }

        onAccepted:
        {
            if(oldName != nameText)
            {
                manager.removeManualInstance(oldName);
            }
            if(portText == "")
            {
                portText = "80" // default http port
            }
            if(pathText.substr(0,1) != "/")
            {
                pathText = "/" + pathText // ensure absolute path
            }
            manager.setManualInstance(nameText, addressText, parseInt(portText), pathText, httpsCheckbox.checked)
        }

        Column {
            anchors.fill: parent
            spacing: UM.Theme.getSize("default_margin").height

            Grid
            {
                columns: 2
                width: parent.width
                verticalItemAlignment: Grid.AlignVCenter
                rowSpacing: UM.Theme.getSize("default_lining").height

                Label
                {
                    text: catalog.i18nc("@label","Instance Name")
                    width: parent.width * 0.4
                }

                TextField
                {
                    id: nameField
                    maximumLength: 20
                    width: parent.width * 0.6
                    validator: RegExpValidator
                    {
                        regExp: /[a-zA-Z0-9\.\-\_]*/
                    }
                }

                Label
                {
                    text: catalog.i18nc("@label","IP Address or Hostname")
                    width: parent.width * 0.4
                }

                TextField
                {
                    id: addressField
                    maximumLength: 30
                    width: parent.width * 0.6
                    validator: RegExpValidator
                    {
                        regExp: /[a-zA-Z0-9\.\-\_]*/
                    }
                }

                Label
                {
                    text: catalog.i18nc("@label","Port Number")
                    width: parent.width * 0.4
                }

                TextField
                {
                    id: portField
                    maximumLength: 5
                    width: parent.width * 0.6
                    validator: RegExpValidator
                    {
                        regExp: /[0-9]*/
                    }
                }

                Label
                {
                    text: catalog.i18nc("@label","Path")
                    width: parent.width * 0.4
                }

                TextField
                {
                    id: pathField
                    maximumLength: 30
                    width: parent.width * 0.6
                    validator: RegExpValidator
                    {
                        regExp: /[a-zA-Z0-9\.\-\_\/]*/
                    }
                }

                Label
                {
                    text: catalog.i18nc("@label","Use HTTPS")
                    width: parent.width * 0.4
                }

                CheckBox
                {
                    id: httpsCheckbox
                }
            }
        }

        rightButtons: [
            Button {
                text: catalog.i18nc("@action:button","Cancel")
                onClicked:
                {
                    manualPrinterDialog.reject()
                    manualPrinterDialog.hide()
                }
            },
            Button {
                text: catalog.i18nc("@action:button", "Ok")
                onClicked:
                {
                    manualPrinterDialog.accept()
                    manualPrinterDialog.hide()
                }
                enabled: manualPrinterDialog.nameText.trim() != "" && manualPrinterDialog.addressText.trim() != ""
                isDefault: true
            }
        ]
    }
}
