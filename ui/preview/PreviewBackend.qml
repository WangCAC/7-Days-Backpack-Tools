import QtQuick

// Only loaded by the development preview. No game files are read or written.
QtObject {
    property QtObject generator: QtObject {
        function layout(capacity, freeSlots, backpackCapacity, columns, maxWidth, appearance) {
            return previewCalculator.layout(capacity, freeSlots, backpackCapacity, columns, maxWidth, appearance || {})
        }
        function autoLayout(capacity, freeSlots, backpackCapacity, columns, maxWidth, mode, currentLayout, displayedCapacity) {
            return previewCalculator.autoLayout(capacity, freeSlots, backpackCapacity, columns, maxWidth, mode, currentLayout, displayedCapacity)
        }
        function suggestedFileUrl(capacity, freeSlots, backpackCapacity, columns, maxWidth) { return "file:///C:/Preview/backpack.zip" }
        function installMod(capacity, freeSlots, backpackCapacity, gamePath, columns, maxWidth) {
            return {ok: true, path: "C:/Games/7 Days To Die/Mods/wangcac-" + capacity + "BigBackpack" + freeSlots + "WB"}
        }
        function removeOtherGeneratedMods(gamePath, installedPath) { return {ok: true, removed: 0} }
        function saveZip(capacity, freeSlots, backpackCapacity, destination, columns, maxWidth) { return {ok: true, path: "C:/Preview/backpack.zip"} }
    }
    property QtObject games: QtObject {
        property var gamePaths: ["C:/Games/7 Days To Die/7DaysToDie.exe", "D:/SteamLibrary/steamapps/common/7 Days To Die/7DaysToDie.exe"]
        property string selectedGamePath: gamePaths[0]
        property bool scanning: false
        property string message: ""
        property bool messageIsError: false
        function scanGames() { message = previewLocalization.strings["gameFound"].replace("%1", selectedGamePath) }
        function selectGame(path) { selectedGamePath = path }
        function addGame(url) { message = previewLocalization.strings["gameSelected"].replace("%1", selectedGamePath) }
        function openModsFolder() { return {ok: true} }
    }
}
