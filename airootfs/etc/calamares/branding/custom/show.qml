import QtQuick 2.5
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Timer {
        interval: 8000
        running: true
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        Text {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 22
            color: "#eeeeee"
            text: "Installing Custom Arch Linux\n\nA rolling-release system with the KDE Plasma desktop."
        }
    }

    Slide {
        Text {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 22
            color: "#eeeeee"
            text: "Administration on this system is done as root.\n\nOpen a terminal and run  su -  to get a root shell.\nsudo is installed but intentionally left unconfigured."
        }
    }

    Slide {
        Text {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 22
            color: "#eeeeee"
            text: "Keep your system current with\n\npacman -Syu\n\nand read the news at archlinux.org before big upgrades."
        }
    }
}
