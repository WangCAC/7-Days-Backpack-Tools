#include <QGuiApplication>
#include <QFontDatabase>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQmlProperty>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QQuickItem>
#include <QTimer>
#include <QTest>
#include <QDir>
#include <QDebug>
#include <QFile>
#include "BackpackGenerator.h"
#include "LocalizationManager.h"
#include "ui/FocusDismissFilter.h"

void require(bool ok, const char *message) { if (!ok) qFatal("%s", message); }
void previewLog(QtMsgType, const QMessageLogContext &, const QString &message) {
    QFile log(QStringLiteral(UI_SOURCE_DIR "/build/UiPreview/runtime.log"));
    if (log.open(QIODevice::WriteOnly | QIODevice::Append)) log.write(message.toUtf8()+"\n");
}
int main(int argc, char **argv) {
    qInstallMessageHandler(previewLog);
    QGuiApplication app(argc, argv);
    app.setOrganizationName("wangcac-ui-preview");
    app.setApplicationName("BackpackToolsPreview");
    QQuickStyle::setStyle("Basic");
    QFontDatabase::addApplicationFont("C:/Windows/Fonts/msyh.ttc");
    QFont font("Microsoft YaHei UI"); font.setWeight(QFont::Normal); app.setFont(font);
    LocalizationManager localization; localization.setLanguage("zh_CN");
    BackpackGenerator calculator;
    QQmlApplicationEngine engine;
    int warnings = 0;
    QObject::connect(&engine, &QQmlEngine::warnings, [&](const QList<QQmlError> &errors) {
        warnings += errors.size(); for (const auto &error : errors) qWarning() << error;
    });
    engine.rootContext()->setContextProperty("previewCalculator", &calculator);
    engine.rootContext()->setContextProperty("previewLocalization", &localization);
    QQmlComponent mocks(&engine, QUrl::fromLocalFile(QStringLiteral(UI_SOURCE_DIR "/ui/preview/PreviewBackend.qml")));
    QScopedPointer<QObject> backend(mocks.create());
    require(!backend.isNull(), "Preview backend failed");
    engine.rootContext()->setContextProperty("backpackGenerator", backend->property("generator").value<QObject *>());
    engine.rootContext()->setContextProperty("gameManager", backend->property("games").value<QObject *>());
    engine.rootContext()->setContextProperty("localization", &localization);
    engine.rootContext()->setContextProperty("uiFontFamily", "Microsoft YaHei UI");
    engine.rootContext()->setContextProperty("appVersion", "1.3.0");
    engine.load(QUrl::fromLocalFile(QStringLiteral(UI_SOURCE_DIR "/Main.qml")));
    require(!engine.rootObjects().isEmpty(), "UI failed to load");
    auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
    require(window, "UI window missing");
    window->setTitle(window->title()+QStringLiteral(" — 界面预览"));
    QList<QQuickItem *> fields;
    for (const char *name : {"capacityInput", "freeInput", "backpackInput", "gameCombo", "previewTypeCombo", "previewQualityCombo", "previewPerkCombo"})
        if (auto *field=window->findChild<QQuickItem *>(name)) fields.append(field);
    window->installEventFilter(new FocusDismissFilter(window, fields));
    const QStringList args=app.arguments();
    if (!args.contains("--capture")) {
        QTimer::singleShot(800, window, [window] {
            qInfo() << "Live preview" << QGuiApplication::platformName() << window->isVisible() << window->size() << window->winId();
            window->grabWindow().save(QStringLiteral(UI_SOURCE_DIR "/build/UiPreview/output/live-preview.png"));
        });
        return app.exec();
    }
    const QString out=QStringLiteral(UI_SOURCE_DIR "/build/UiPreview/output"); QDir().mkpath(out);
    auto item=[&](const char *name) { auto *object=window->findChild<QQuickItem *>(name); require(object,name); return object; };
    auto object=[&](const char *name) { auto *value=window->findChild<QObject *>(name); require(value,name); return value; };
    auto *carryPreview=object("backpackPreview");
    object("capacityInput")->setProperty("text","200");
    object("freeInput")->setProperty("text","50");
    object("backpackInput")->setProperty("text","200");
    carryPreview->setProperty("physicalEnabled",false);
    carryPreview->setProperty("perkEnabled",true);
    const int characterFreeCounts[5]={62,125,200,200,200};
    const int equippedFreeCounts[5]={62,125,201,297,400};
    for (int rank=0; rank<5; ++rank) {
        carryPreview->setProperty("perkLevel",rank);
        QCoreApplication::processEvents();
        require(carryPreview->property("freeCount").toInt()==characterFreeCounts[rank]
                && carryPreview->property("carrySlots").toInt()==equippedFreeCounts[rank],
                "unequipped preview lost global carry allowance");
        carryPreview->setProperty("physicalEnabled",true);
        QCoreApplication::processEvents();
        require(carryPreview->property("totalSlots").toInt()==400
                && carryPreview->property("freeCount").toInt()==equippedFreeCounts[rank],
                "equipped backpack did not reveal global carry allowance");
        carryPreview->setProperty("physicalEnabled",false);
        QCoreApplication::processEvents();
        require(carryPreview->property("freeCount").toInt()==characterFreeCounts[rank]
                && carryPreview->property("carrySlots").toInt()==equippedFreeCounts[rank],
                "unequipping changed global carry allowance");
    }
    carryPreview->setProperty("perkLevel",2);
    carryPreview->setProperty("perkEnabled",false);
    require(carryPreview->property("freeCount").toInt()==50,"disabled skill added carry slots");
    carryPreview->setProperty("perkEnabled",true);
    auto capture=[&](const QString &name) { QTest::qWait(300); require(window->grabWindow().save(out+"/"+name+".png"),"screenshot failed"); };
    auto click=[&](const char *name) {
        auto *control=item(name); const QPoint point=control->mapToScene(QPointF(control->width()/2,control->height()/2)).toPoint();
        QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,point); QTest::qWait(300);
    };
    window->resize(1460,850); capture("01-main");
    auto *helpControl=item("previewModeHelpButton");
    auto *helpArtwork=helpControl->property("contentItem").value<QQuickItem *>();
    require(helpArtwork && qAbs(helpArtwork->width()-helpArtwork->height())<0.01,
            "mode help SVG is stretched instead of circular");
    require(helpControl->mapToScene(QPointF(helpControl->width(),0)).x()
            < item("previewModeButton")->mapToScene(QPointF(0,0)).x(),"help remains inside mode button");
    require(object("modeStatusLabel")->property("text").toString().contains(QStringLiteral("预览模式")),
            "header does not show preview mode");
    const qreal firstPulse=object("modeStatusDot")->property("opacity").toReal();
    QTest::qWait(650);
    const qreal secondPulse=object("modeStatusDot")->property("opacity").toReal();
    QTest::qWait(650);
    require(qAbs(firstPulse-secondPulse)>0.05
            || qAbs(firstPulse-object("modeStatusDot")->property("opacity").toReal())>0.05,
            "mode status dot does not breathe");
    capture("14-character-rank3");
    carryPreview->setProperty("physicalEnabled",true);
    auto weighted=[&](int index) {
        QVariant result;
        require(QMetaObject::invokeMethod(carryPreview,"slotWeighted",Q_RETURN_ARG(QVariant,result),
                                          Q_ARG(QVariant,QVariant(index))),"cannot inspect preview slot");
        return result.toBool();
    };
    require(!carryPreview->property("gameMode").toBool(),"preview mode is not the default");
    require(carryPreview->property("characterFreeCount").toInt()==200
            && carryPreview->property("physicalFreeCount").toInt()==1,"global unlock boundary incorrect");
    require(!weighted(133) && !weighted(134) && !weighted(199)
            && !weighted(200) && weighted(201) && weighted(266) && weighted(267),
            "preview mode does not unlock sequentially");
    capture("15-marked-preview");
    click("gameModeButton");
    require(object("modeStatusLabel")->property("text").toString().contains(QStringLiteral("游戏模式")),
            "header did not update to game mode");
    require(carryPreview->property("gameMode").toBool(),"game mode button did not switch mode");
    require(!weighted(199) && !weighted(200) && weighted(201) && weighted(266),"game mode is not sequential");
    capture("16-game-mode");
    click("gameModeHelpButton");
    require(object("modeHelpDialog")->property("visible").toBool()
            && object("modeHelpDialog")->property("gameDescription").toBool(),"game mode help missing");
    capture("17-game-mode-help");
    QMetaObject::invokeMethod(object("modeHelpDialog"),"close"); QTest::qWait(300);
    click("previewModeButton");
    require(!carryPreview->property("gameMode").toBool() && !weighted(199) && !weighted(200) && weighted(201),
            "switching modes changed global unlock distribution");
    click("previewModeHelpButton");
    require(object("modeHelpDialog")->property("visible").toBool()
            && !object("modeHelpDialog")->property("gameDescription").toBool(),"preview mode help missing");
    capture("18-preview-mode-help");
    QMetaObject::invokeMethod(object("modeHelpDialog"),"close"); QTest::qWait(300);
    carryPreview->setProperty("backpackType",0); carryPreview->setProperty("backpackQuality",0);
    require(carryPreview->property("totalSlots").toInt()==208
            && carryPreview->property("physicalFreeCount").toInt()==1
            && carryPreview->property("freeCount").toInt()==201,"small backpack changed global unlock boundary");
    carryPreview->setProperty("gameMode",true);
    require(carryPreview->property("freeCount").toInt()==201,"game mode pooled count incorrect");
    carryPreview->setProperty("gameMode",false);
    carryPreview->setProperty("backpackType",2); carryPreview->setProperty("backpackQuality",5);
    // Reproduce the author's in-game observation: rank 2 adds nine, cumulative ten.
    const QVariantMap observed=calculator.layout(40,32,48);
    const QVariantList observedRanks=observed.value("perkRank").toList();
    const QVariantList observedTotals=observed.value("perk").toList();
    require(observedRanks==QVariantList({1,9,10,18,18})
            && observedTotals==QVariantList({1,10,20,38,56}),"40/32/48 skill distribution changed");
    object("capacityInput")->setProperty("text","40");
    object("freeInput")->setProperty("text","32");
    object("backpackInput")->setProperty("text","48");
    carryPreview->setProperty("perkLevel",1);
    carryPreview->setProperty("physicalEnabled",false);
    require(carryPreview->property("carrySlots").toInt()==42
            && carryPreview->property("totalSlots").toInt()==40
            && carryPreview->property("freeCount").toInt()==40,"rank 2 should fully unlock visible character slots");
    capture("20-global-unlock-no-backpack");
    carryPreview->setProperty("physicalEnabled",true);
    for (bool gameMode : {false,true}) {
        carryPreview->setProperty("gameMode",gameMode);
        require(carryPreview->property("carrySlots").toInt()==42
                && carryPreview->property("totalSlots").toInt()==88
                && carryPreview->property("freeCount").toInt()==42
                && !weighted(39) && !weighted(40) && !weighted(41) && weighted(42),
                "equipped rank 2 should show 42 unencumbered and 46 encumbered slots in both modes");
    }
    capture("21-global-unlock-with-backpack");
    carryPreview->setProperty("physicalEnabled",false);
    require(carryPreview->property("carrySlots").toInt()==42
            && carryPreview->property("freeCount").toInt()==40,"unequipping discarded hidden carry allowance");
    carryPreview->setProperty("gameMode",false);
    object("capacityInput")->setProperty("text","200");
    object("freeInput")->setProperty("text","50");
    object("backpackInput")->setProperty("text","200");
    // Desktop controls keep the same geometry and row grouping in both languages.
    window->resize(1200,700);
    QTest::qWait(300);
    const char *parityNames[]={"characterOptionsRow","physicalOptions","perkOptions",
                              "previewTypeCombo","previewQualityCombo","previewPerkCombo",
                              "capacityInput","freeInput","backpackInput"};
    QList<QRectF> chineseGeometry;
    for (const char *name : parityNames) {
        auto *control=item(name);
        chineseGeometry.append(QRectF(control->mapToScene(QPointF()),control->size()));
    }
    require(qAbs(chineseGeometry[0].top()-chineseGeometry[1].top())<0.1
            && qAbs(chineseGeometry[0].top()-chineseGeometry[2].top())<0.1,
            "Chinese desktop preview controls wrap unexpectedly");
    capture("22-chinese-layout");
    localization.setLanguage("en_US"); QTest::qWait(300);
    auto *perkLabel=object("perkCheck")->property("contentItem").value<QObject *>();
    require(perkLabel && perkLabel->property("lineCount").toInt()==1,"English Pack Mule label wraps");
    for (int i=0; i<int(sizeof(parityNames)/sizeof(parityNames[0])); ++i) {
        auto *control=item(parityNames[i]);
        const QRectF englishGeometry(control->mapToScene(QPointF()),control->size());
        const QRectF difference(englishGeometry.topLeft()-chineseGeometry[i].topLeft(),
                                englishGeometry.size()-chineseGeometry[i].size());
        require(qAbs(difference.x())<0.1 && qAbs(difference.y())<0.1
                && qAbs(difference.width())<0.1 && qAbs(difference.height())<0.1,
                "English and Chinese desktop control layouts differ");
    }
    capture("23-english-layout");
    localization.setLanguage("zh_CN"); window->resize(1460,850); QTest::qWait(300);
    carryPreview->setProperty("physicalEnabled",false);
    carryPreview->setProperty("perkEnabled",false);
    carryPreview->setProperty("perkLevel",0);
    auto *scrollbar=object("settingsScrollBar");
    require(scrollbar->property("size").toReal()>=1 && !scrollbar->property("visible").toBool(),"unnecessary sidebar scrollbar remains");
    click("capacityInput"); require(item("capacityInput")->hasActiveFocus(),"numeric focus missing"); capture("02-input-focus");
    QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,QPoint(1200,760)); QTest::qWait(160);
    require(!item("capacityInput")->hasActiveFocus(),"numeric focus does not dismiss");
    click("detailsButton"); capture("03-details"); QMetaObject::invokeMethod(object("detailsDialog"),"close"); QTest::qWait(300);
    click("gameCombo"); capture("04-game-menu");
    QMetaObject::invokeMethod(item("gameCombo")->property("popup").value<QObject *>(),"close"); QTest::qWait(300);
    QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,QPoint(1200,760)); QTest::qWait(150);
    require(!item("gameCombo")->hasActiveFocus(),"combo focus does not dismiss");
    auto *button=item("installButton"); const QPoint center=button->mapToScene(QPointF(button->width()/2,button->height()/2)).toPoint();
    QTest::mouseMove(window,center); capture("05-button-hover");
    QTest::mousePress(window,Qt::LeftButton,Qt::NoModifier,center); QTest::qWait(90);
    require(button->property("down").toBool(),"button press not detected");
    require(window->grabWindow().save(out+"/06-button-pressed.png"),"pressed capture");
    QTest::mouseRelease(window,Qt::LeftButton,Qt::NoModifier,center); capture("07-install-dialog");
    require(object("cleanupCheckBox")->property("checked").toBool(),"cleanup default lost");
    QMetaObject::invokeMethod(object("noticeConfirmButton"),"clicked"); QTest::qWait(300);
    click("aboutButton"); capture("08-about"); QMetaObject::invokeMethod(object("aboutDialog"),"close"); QTest::qWait(300);
    click("languageButton"); capture("09-language-menu"); QMetaObject::invokeMethod(object("languageMenu"),"close");
    auto *preview=object("backpackPreview"); preview->setProperty("physicalEnabled",true); preview->setProperty("perkEnabled",true); preview->setProperty("perkLevel",2);
    object("capacityInput")->setProperty("text","250"); object("freeInput")->setProperty("text","125"); capture("10-backpack-states");
    preview->setProperty("characterEnabled",false); capture("11-disabled-preview"); preview->setProperty("characterEnabled",true);
    localization.setLanguage("en_US"); window->resize(760,520); capture("12-english-small");
    click("gameModeHelpButton"); capture("19-english-mode-help");
    QMetaObject::invokeMethod(object("modeHelpDialog"),"close"); QTest::qWait(300);
    require(scrollbar->property("size").toReal()<1 && scrollbar->property("visible").toBool(),"small window cannot scroll");
    auto *flick=item("controlsFlick"); flick->setProperty("contentY",150); capture("13-small-scrolled");
    require(warnings==0,"QML warnings during interaction");
    for(auto *image : window->findChildren<QQuickItem *>()) {
        const QString source=image->property("source").toUrl().toString();
        if(source.startsWith("qrc:/assets/") && source.endsWith(".svg"))
            require(image->property("status").toInt()==1,"SVG asset did not load");
    }
    qInfo()<<"UI preview passed: layout, both languages, menus/dialogs, input focus dismissal, scrollbar range, hover/pressed ripple, backpack preview";
    return 0;
}
