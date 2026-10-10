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
#include <QDomDocument>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJSValue>
#include <QColor>
#include <cmath>
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
    QScopedPointer<QObject> backend;
    QQmlApplicationEngine engine;
    int warnings = 0;
    QObject::connect(&engine, &QQmlEngine::warnings, [&](const QList<QQmlError> &errors) {
        warnings += errors.size(); for (const auto &error : errors) qWarning() << error;
    });
    engine.rootContext()->setContextProperty("previewCalculator", &calculator);
    engine.rootContext()->setContextProperty("previewLocalization", &localization);
    QQmlComponent mocks(&engine, QUrl::fromLocalFile(QStringLiteral(UI_SOURCE_DIR "/ui/preview/PreviewBackend.qml")));
    backend.reset(mocks.create());
    require(!backend.isNull(), "Preview backend failed");
    engine.rootContext()->setContextProperty("backpackGenerator", backend->property("generator").value<QObject *>());
    engine.rootContext()->setContextProperty("gameManager", backend->property("games").value<QObject *>());
    engine.rootContext()->setContextProperty("localization", &localization);
    engine.rootContext()->setContextProperty("uiFontFamily", "Microsoft YaHei UI");
    engine.rootContext()->setContextProperty("appVersion", "1.4.1");
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
    if (args.contains("--v140")) {
        const int outputArg=args.indexOf("--v140")+1;
        require(outputArg<args.size(),"v1.4 verification output directory missing");
        const QString output=args[outputArg];
        require(QDir().mkpath(output),"cannot create verification output");
        auto item=[&](const char *name) {
            auto *value=window->findChild<QQuickItem *>(name);
            require(value,name); return value;
        };
        auto *columns=item("columnsSlider"), *width=item("widthSlider");
        auto *preview=item("backpackPreview"), *inventory=item("inventoryWindow");
        auto *viewport=item("previewViewport"), *grid=item("previewGrid"), *holder=item("previewHolder");
        auto settle=[&]() { QTest::qWait(180); window->grabWindow(); QTest::qWait(120); };
        auto capture=[&](const char *name) {
            settle(); require(window->grabWindow().save(output+"/"+name+".png"),"screenshot failed");
        };
        window->resize(1200,700); settle();
        require(window->property("capacity").toInt()==48 && window->property("freeSlots").toInt()==32
                && window->property("backpackCapacity").toInt()==48,"defaults are not 48/32/48");
        require(columns->property("value").toInt()==8 && width->property("value").toInt()==603,
                "default layout is not eight columns at vanilla width");
        require(inventory->width()==603 && inventory->property("scale").toReal()>0,
                "vanilla preview width or projection incorrect");
        const qreal referenceScale=holder->property("referenceScale").toReal();
        const qreal vanillaDisplayWidth=inventory->width()*inventory->property("scale").toReal();
        capture("01-default");
        if (args.contains("--v141") || args.contains("--auto-fit")) {
            // Two empty rows plus a partial row: normal keeps the two rows,
            // strong keeps only occupied rows, keep-height preserves all space.
            auto snapshot=calculator.layout(48,32,144,16,1305);
            snapshot["height"]=471; snapshot["viewportHeight"]=419;
            const int viewHeights[3]={400,240,419}, windowHeights[3]={452,292,471};
            for (int mode=0;mode<3;++mode) {
                const auto fit=calculator.autoLayout(48,32,144,16,1305,mode,snapshot,48);
                require(fit.value("valid").toBool(),"edge fit rejected valid snapshot");
                require(fit.value("cols").toInt()==16 && fit.value("cell").toInt()==80
                        && fit.value("width").toInt()==1299 && fit.value("stackScale")==snapshot.value("stackScale"),
                        "edge fitting changed chosen columns or displayed cell size");
                require(fit.value("viewportHeight").toInt()==viewHeights[mode]
                        && fit.value("height").toInt()==windowHeights[mode],"edge policy handled empty space incorrectly");
                require(fit.value("maxCapacity").toInt()==232 && fit.value("perk")==snapshot.value("perk")
                        && fit.value("backpacks")==snapshot.value("backpacks"),"fitting changed capacity or skills");
                const auto options=fit.value("appearance").toMap();
                const auto reapplied=calculator.layout(48,32,144,16,fit.value("maxWidth").toInt(),options);
                require(reapplied.value("height")==fit.value("height") && reapplied.value("cell")==fit.value("cell"),
                        "reapplying fitted slider value changed geometry");
                const QString gameRoot=output+"/fake-game"; require(QDir().mkpath(gameRoot),"fake game directory");
                QFile exe(gameRoot+"/7DaysToDie.exe"); require(exe.open(QIODevice::WriteOnly),"fake game exe"); exe.close();
                const auto installed=calculator.installMod(48,32,144,exe.fileName(),16,1299,options);
                require(installed.value("ok").toBool(),"fitted install failed");
                QFile file(installed.value("path").toString()+"/Config/XUi_InGame/windows.xml");
                require(file.open(QIODevice::ReadOnly),"fitted XML missing"); const QByteArray xml=file.readAll();
                QDomDocument document; require(bool(document.setContent(xml)),"fitted XML invalid");
                auto value=[&](const QString &xpath,const QString &attribute=QString()) {
                    for(auto entry=document.documentElement().firstChildElement();!entry.isNull();entry=entry.nextSiblingElement())
                        if(entry.attribute("xpath")==xpath && (attribute.isEmpty()?entry.tagName()=="set":entry.attribute("name")==attribute)) return entry.text();
                    return QString();
                };
                const QString bp="/windows/window[@name='windowBackpack']", content=bp+"/rect[@name='content']";
                require(value(bp+"/@height").toInt()==windowHeights[mode]
                        && value(content+"/scrollview","height").toInt()==viewHeights[mode]
                        && value(content+"/scrollview","width")=="1280", "exported edge dimensions disagree");
                require(value(content+"/defaultscrollbar","pos")=="1283,-3"
                        && value(content+"/defaultscrollbar","barheight").toInt()==viewHeights[mode],"scrollbar is detached from grid edge");
                const auto saved=calculator.saveZip(48,32,144,QUrl::fromLocalFile(output+QString("/mode-%1.zip").arg(mode)),16,1299,options);
                QFile zip(saved.value("path").toString());
                require(saved.value("ok").toBool() && zip.open(QIODevice::ReadOnly) && zip.readAll().contains(xml),
                        "fitted ZIP differs from installation");
            }
            for(int cols : {8,12,16,20}) for(int maxWidth : {603,900,1305,1678}) {
                const auto baseline=calculator.layout(48,32,144,cols,maxWidth);
                require(baseline.value("queueX").toInt()+baseline.value("queueCols").toInt()*75==394,
                        "crafting queue extends beyond crafting list");
                require(13+baseline.value("queueRows").toInt()*75<=baseline.value("queueHeight").toInt(),
                        "queue window does not contain queue rows");
                for(int mode : {0,1,2}) {
                    const auto fit=calculator.autoLayout(48,32,144,cols,maxWidth,mode,baseline,48);
                    require(fit.value("valid").toBool(),"range edge fit failed");
                    require(fit.value("width").toInt()==fit.value("cols").toInt()*fit.value("cell").toInt()+19,
                            "fitted right edge contains extra gutter");
                    if(mode<2) require(fit.value("height").toInt()==fit.value("viewportHeight").toInt()+52,
                                       "fitted bottom edge contains extra margin");
                }
            }
            auto click=[&](const char *name) {
                auto *control=item(name); const QPoint point=control->mapToScene(QPointF(control->width()/2,control->height()/2)).toPoint();
                QTest::mouseClick(window,Qt::LeftButton,Qt::NoModifier,point); settle();
            };
            auto popup=window->findChild<QObject *>("edgeFitDialog"); require(popup,"fit dialog missing");
            item("backpackInput")->setProperty("text","144"); columns->setProperty("value",16); width->setProperty("value",1305);
            capture("10-before-fit");
            click("autoFitButton"); require(popup->property("visible").toBool(),"Auto fit does not open options");
            capture("11-options-chinese");
            auto *normal=item("normalEdgeOption");
            auto *explanation=item("edgeExplanationPanel");
            const QPointF explanationPosition=explanation->mapToScene(QPointF());
            const QSizeF explanationSize=explanation->size();
            for(int repeat=0;repeat<3;++repeat) for(const char *name : {"normalEdgeOption","strongEdgeOption","keepHeightOption"}) {
                auto *option=item(name);
                QTest::mouseMove(window,option->mapToScene(QPointF(option->width()/2,option->height()/2)).toPoint()); QTest::qWait(40);
                auto *background=option->property("background").value<QQuickItem *>(); require(background,"radio background missing");
                const QColor color=background->property("color").value<QColor>();
                require(color.red()>220 && color.green()>230,"hover background interpolates through dark colours");
                require(explanation->mapToScene(QPointF())==explanationPosition && explanation->size()==explanationSize,
                        "explanation moves or resizes on hover");
            }
            auto *strong=item("strongEdgeOption");
            QTest::mouseMove(window,strong->mapToScene(QPointF(strong->width()/2,strong->height()/2)).toPoint()); QTest::qWait(220);
            require(item("edgeExplanationText")->property("text").toString().contains(QStringLiteral("收掉")),
                    "hover explanation did not update");
            require(!window->findChild<QObject *>("normalEdgeTooltip"),"floating dark tooltip remains");
            capture("12-fixed-hover-explanation");
            click("edgeFitConfirmButton");
            require(window->property("columns").toInt()==16 && grid->property("cellWidth").toInt()==80,
                    "UI fitting changes selected layout"); capture("13-normal");
            click("autoFitButton"); click("strongEdgeOption");
            require(!item("normalEdgeOption")->property("checked").toBool(),"radio options are not exclusive");
            click("edgeFitConfirmButton"); require(grid->height()==240 && inventory->height()==292,"strong UI fit did not remove empty rows");
            auto *scrollbar=item("inventoryScrollBar");
            auto *thumb=scrollbar->property("contentItem").value<QQuickItem *>();
            require(scrollbar->isVisible() && thumb && thumb->opacity()>0 && scrollbar->property("size").toReal()>=1,
                    "scrollbar disappears when all slots fit");
            capture("14-strong");
            preview->setProperty("physicalEnabled",true); settle();
            require(preview->property("totalSlots").toInt()==192 && grid->property("contentHeight").toReal()>grid->height(),
                    "strong fit prevents additional backpack slots");
            require(scrollbar->isVisible() && scrollbar->property("size").toReal()<1,"overflow scrollbar not visible");
            preview->setProperty("physicalEnabled",false);
            width->setProperty("value",1305); settle(); const qreal previousHeight=inventory->height();
            click("autoFitButton"); click("keepHeightOption"); click("edgeFitConfirmButton");
            require(inventory->height()==previousHeight,"keep-height mode changes height"); capture("15-keep-height");
            localization.setLanguage("en_US"); click("autoFitButton"); capture("16-options-english");
            click("edgeFitCancelButton");
            require(warnings==0,"QML warnings in edge fitting");
            QFile report(output+"/v141-check.json"); require(report.open(QIODevice::WriteOnly),"report missing");
            report.write(QJsonDocument(QJsonObject{{"passed",true},{"normalRetainsWholeBlankRows",true},
                {"strongRemovesBlankRows",true},{"keepHeightPreserved",true},{"queueRightEdge",394},
                {"capacityAndSkillsPreserved",true},{"exportAndInstallMatch",true},
                {"persistentScrollbar",true},{"stableHoverExplanation",true},{"qmlWarnings",warnings}}).toJson());
            return 0;
        }
        if (args.contains("--whole-rows")) {
            for (int cols : {8,12,20}) for (int maxWidth : {603,858,1678}) {
                columns->setProperty("value",cols); width->setProperty("value",maxWidth);
                preview->setProperty("physicalEnabled",false); settle();
                const auto expected=calculator.layout(48,32,48,cols,maxWidth);
                require(grid->height()==expected.value("viewportHeight").toInt()
                        && inventory->height()==expected.value("height").toInt(),
                        "preview differs from generated viewport geometry");
                require(qAbs(std::remainder(grid->height(),grid->property("cellHeight").toReal()))<0.001,
                        "viewport clips part of a row");
                for (bool gameMode : {false,true}) {
                    preview->setProperty("gameMode",gameMode);
                    preview->setProperty("physicalEnabled",true); settle();
                    require(grid->height()==expected.value("viewportHeight").toInt()
                            && preview->property("totalSlots").toInt()==96,
                            "equipping a backpack changes viewport or loses slots");
                    preview->setProperty("physicalEnabled",false);
                }
            }
            preview->setProperty("gameMode",false);
            columns->setProperty("value",8); width->setProperty("value",1678); settle();
            const auto expected=calculator.layout(48,32,48,8,1678);
            require(expected.value("cell").toInt()==207 && expected.value("visibleRows").toInt()==3
                    && grid->height()==621 && inventory->height()==678,
                    "eight-column widest regression is not three complete rows");
            const auto vanilla=calculator.layout(48,32,48,8,603);
            require(expected.value("height").toReal()*expected.value("stackScale").toReal()
                    >=vanilla.value("height").toReal()*vanilla.value("stackScale").toReal(),
                    "widest panel is shorter than the vanilla-width panel");
            grid->setProperty("contentY",0); capture("08-widest-complete-rows");
            grid->setProperty("contentY",grid->property("contentHeight").toReal()-grid->height()); settle();
            auto *content=grid->property("contentItem").value<QQuickItem *>();
            require(content,"inventory content item missing");
            QQuickItem *lastSlot=nullptr;
            for (auto *child : content->childItems())
                if (child->property("index").isValid() && child->property("index").toInt()==47) lastSlot=child;
            require(lastSlot,"last character slot cannot be reached by scrolling");
            const QPointF bottom=lastSlot->mapToItem(grid,QPointF(0,lastSlot->height()));
            require(lastSlot->mapToItem(grid,QPointF()).y()>=-0.1 && bottom.y()<=grid->height()+0.1,
                    "last row is clipped at the bottom");
            capture("09-widest-last-row");
            const QString gameRoot=output+"/fake-game"; require(QDir().mkpath(gameRoot),"cannot create fake game");
            QFile exe(gameRoot+"/7DaysToDie.exe"); require(exe.open(QIODevice::WriteOnly),"cannot create fake executable"); exe.close();
            const auto installed=calculator.installMod(48,32,48,exe.fileName(),8,1678);
            require(installed.value("ok").toBool(),"regression mod generation failed");
            QFile file(installed.value("path").toString()+"/Config/XUi_InGame/windows.xml");
            require(file.open(QIODevice::ReadOnly),"regression windows.xml missing");
            const QByteArray xml=file.readAll(); QDomDocument document; require(bool(document.setContent(xml)),"invalid XML");
            bool sawViewport=false;
            const auto attributes=document.elementsByTagName("setattribute");
            for(int i=0;i<attributes.size();++i) {
                const auto entry=attributes.at(i).toElement();
                if(entry.attribute("xpath").contains("window[@name='windowBackpack']")
                   && entry.attribute("xpath").endsWith("/scrollview") && entry.attribute("name")=="height") {
                    sawViewport=true; require(entry.text()=="621","game scroll viewport does not match preview");
                }
            }
            require(sawViewport,"game viewport height patch missing");
            const auto saved=calculator.saveZip(48,32,48,QUrl::fromLocalFile(output+"/whole-rows-mod.zip"),8,1678);
            require(saved.value("ok").toBool(),"regression ZIP generation failed");
            QFile zip(saved.value("path").toString()); require(zip.open(QIODevice::ReadOnly) && zip.readAll().contains(xml),
                    "installed and exported viewport heights disagree");
            require(warnings==0,"QML warnings during complete-row check");
            QFile report(output+"/whole-rows-check.json"); require(report.open(QIODevice::WriteOnly),"cannot save regression report");
            report.write(QJsonDocument(QJsonObject{{"passed",true},{"visibleRows",3},{"cellSize",207},
                         {"viewportHeight",621},{"windowHeight",678},{"lastSlotReachable",true},{"installAndExportMatch",true},
                         {"qmlWarnings",warnings}}).toJson());
            return 0;
        }
        if (args.contains("--alignment")) {
            localization.setLanguage("en_US"); capture("02-english");
            window->resize(760,520); capture("03-english-small");
            return 0;
        }
        if (args.contains("--snapshot-only")) return 0;
        require(!item("settingsScrollBar")->isVisible(),"settings need unnecessary scrolling at default desktop size");
        const auto perk=calculator.layout(48,32,48).value("perk");
        for(int capacity : {1,48,250,5000}) for(int cols : {8,9,15,20}) for(int maxWidth : {603,858,1678}) {
            const auto data=calculator.layout(capacity,qMin(32,capacity),48,cols,maxWidth);
            require(data.value("valid").toBool() && data.value("cols").toInt()==cols,
                    "requested column count was changed");
            require(data.value("width").toInt()<=maxWidth && data.value("cell").toInt()>0,
                    "inventory exceeds chosen maximum width");
            require(data.value("gridRows").toInt()*cols>=capacity+48+40,
                    "equipped items have no grid space");
        }
        require(!calculator.layout(48,32,48,7,603).value("valid").toBool()
                && !calculator.layout(48,32,48,21,603).value("valid").toBool()
                && !calculator.layout(48,32,48,8,602).value("valid").toBool()
                && !calculator.layout(48,32,48,8,1679).value("valid").toBool(),"layout limits not enforced");
        // Exercise the real slider interaction, including snapping at both ends.
        auto dragToEnd=[&](QQuickItem *slider) {
            const qreal padding=slider->property("leftPadding").toReal();
            const QPoint start=slider->mapToScene(QPointF(padding+7,slider->height()/2)).toPoint();
            const QPoint end=slider->mapToScene(QPointF(slider->width()-padding-1,slider->height()/2)).toPoint();
            QTest::mousePress(window,Qt::LeftButton,Qt::NoModifier,start);
            QTest::mouseMove(window,end,80); QTest::mouseRelease(window,Qt::LeftButton,Qt::NoModifier,end);
            settle();
        };
        dragToEnd(columns); require(columns->property("value").toInt()==20,"column slider does not drag to twenty");
        require(grid->property("cellWidth").toInt()==28,"narrow twenty-column preview is incorrect");
        capture("02-twenty-vanilla");
        dragToEnd(width); require(width->property("value").toInt()==1678,"width slider does not drag to widest");
        require(inventory->width()>1600 && inventory->width()<=1678
                && qAbs(holder->property("referenceScale").toReal()-referenceScale)<0.001,
                "width slider changed the shared projection");
        require(inventory->width()*inventory->property("scale").toReal()>vanillaDisplayWidth,
                "widest backpack is not visibly wider than vanilla");
        const QVariant current=window->property("currentLayout");
        const QVariantMap currentData=current.metaType()==QMetaType::fromType<QJSValue>()
            ? current.value<QJSValue>().toVariant().toMap() : current.toMap();
        require(currentData.value("perk")==perk,
                "layout sliders changed carry allowance");
        capture("03-widest");
        for(int cols : {8,15,20}) for(int maxWidth : {603,858,1200,1678}) {
            columns->setProperty("value",cols); width->setProperty("value",maxWidth); settle();
            const qreal scale=inventory->property("scale").toReal();
            require(qAbs(holder->property("referenceScale").toReal()-referenceScale)<0.001,
                    "settings changed the shared projection");
            require(inventory->x()>=0 && inventory->x()+inventory->width()*scale<=viewport->width()+0.1
                    && inventory->y()>=0 && inventory->y()+inventory->height()*scale<=viewport->height()+0.1,
                    "backpack frame is clipped");
            require(qAbs(std::remainder(grid->height(),grid->property("cellHeight").toReal()))<0.001,
                    "viewport clips part of a row");
        }
        columns->setProperty("value",8); width->setProperty("value",1678);
        capture("04-eight-columns-widest");
        preview->setProperty("physicalEnabled",true); preview->setProperty("perkEnabled",true);
        preview->setProperty("perkLevel",1);
        for(bool gameMode : {false,true}) {
            preview->setProperty("gameMode",gameMode);
            require(preview->property("totalSlots").toInt()==96 && preview->property("freeCount").toInt()==44,
                    "layout change broke preview capacity");
        }
        preview->setProperty("gameMode",false);
        columns->setProperty("value",15); width->setProperty("value",858);
        capture("05-marked-preview");
        const QRectF columnsBounds(columns->mapToScene(QPointF()),columns->size());
        localization.setLanguage("en_US"); settle();
        require(QRectF(columns->mapToScene(QPointF()),columns->size())==columnsBounds,
                "English slider placement differs from Chinese");
        capture("06-english");
        window->resize(760,520); settle();
        const qreal smallScale=inventory->property("scale").toReal();
        require(inventory->x()+inventory->width()*smallScale<=viewport->width()+0.1
                && inventory->y()+inventory->height()*smallScale<=viewport->height()+0.1,
                "small window clips the backpack frame");
        require(item("controlsFlick")->property("contentHeight").toReal()>item("controlsFlick")->height(),
                "small window cannot reach settings");
        capture("07-small-window");
        const QString gameRoot=output+"/fake-game";
        require(QDir().mkpath(gameRoot),"cannot create fake game");
        QFile exe(gameRoot+"/7DaysToDie.exe"); require(exe.open(QIODevice::WriteOnly),"cannot create test executable"); exe.close();
        const auto result=calculator.installMod(250,125,48,exe.fileName(),15,858);
        require(result.value("ok").toBool(),"mod install failed");
        QFile xml(result.value("path").toString()+"/Config/XUi_InGame/windows.xml");
        require(xml.open(QIODevice::ReadOnly),"generated windows.xml missing");
        const QByteArray generatedXml=xml.readAll(); QDomDocument document;
        require(bool(document.setContent(generatedXml)),"generated windows.xml invalid");
        const auto selected=calculator.layout(250,125,48,15,858);
        bool sawCols=false,sawWidth=false,sawRows=false;
        const auto sets=document.elementsByTagName("set");
        for(int i=0;i<sets.size();++i) {
            const auto entry=sets.at(i).toElement(); const QString xpath=entry.attribute("xpath");
            if(!xpath.contains("window[@name='windowBackpack']")) continue;
            if(xpath.endsWith("grid[@name='inventory']/@cols")) {sawCols=true; require(entry.text()=="15","installed columns incorrect");}
            if(xpath.endsWith("window[@name='windowBackpack']/@width")) {sawWidth=true; require(entry.text().toInt()==selected.value("width").toInt(),"installed width incorrect");}
            if(xpath.endsWith("grid[@name='inventory']/@rows")) {sawRows=true; require(entry.text().toInt()==selected.value("gridRows").toInt(),"installed scroll rows incorrect");}
        }
        require(sawCols && sawWidth && sawRows,"generated XML lacks layout settings");
        const auto saved=calculator.saveZip(250,125,48,QUrl::fromLocalFile(output+"/layout-mod.zip"),15,858);
        require(saved.value("ok").toBool(),"mod export failed");
        QFile zip(saved.value("path").toString()); require(zip.open(QIODevice::ReadOnly),"export missing");
        require(zip.readAll().contains(generatedXml),"export and installation disagree");
        require(warnings==0,"QML warnings during v1.4 verification");
        QFile report(output+"/verification.json"); require(report.open(QIODevice::WriteOnly),"report write failed");
        report.write(QJsonDocument(QJsonObject{{"passed",true},{"defaults","48/32/48, 8 columns, vanilla width"},
                     {"sharedPreviewProjection",true},{"completeRows",true},
                     {"fullWidthRangeVisible",true},{"maximumWidth",1678},{"installAndExportMatch",true},
                     {"qmlWarnings",warnings}}).toJson());
        return 0;
    }
    if (args.contains("--readme")) {
        window->resize(1200,700);
        auto findItem=[&](const char *name) {
            auto *control=window->findChild<QQuickItem *>(name);
            require(control,name); return control;
        };
        auto *preview=findItem("backpackPreview");
        auto bounds=[](QQuickItem *control) {
            require(control,"screenshot target missing");
            return QRectF(control->mapToScene(QPointF()),control->size());
        };
        auto popupBounds=[&](QObject *popup) {
            require(popup,"screenshot popup missing");
            auto *content=popup->property("contentItem").value<QQuickItem *>();
            require(content,"screenshot popup content missing");
            return bounds(content->parentItem());
        };
        auto *games=backend->property("games").value<QObject *>();
        games->setProperty("gamePaths",QStringList({"C:/Games/7 Days To Die/7DaysToDie.exe"}));
        games->setProperty("selectedGamePath","C:/Games/7 Days To Die/7DaysToDie.exe");
        for (const QString &language : {QStringLiteral("zh_CN"),QStringLiteral("en_US")}) {
            localization.setLanguage(language);
            const QString output=QStringLiteral(UI_SOURCE_DIR "/assets/screenshots/")
                    +(language=="zh_CN" ? "zh-cn" : "en");
            require(QDir().mkpath(output),"cannot create screenshot directory");
            auto capture=[&](const QString &name,const QRectF &area=QRectF()) {
                QTest::qWait(450);
                // Offscreen captures start frame-driven transitions; let them settle.
                window->grabWindow(); QTest::qWait(300);
                window->grabWindow(); QTest::qWait(300);
                const QImage image=window->grabWindow();
                require(!image.isNull(),"documentation screenshot failed");
                QImage shot=image;
                if (!area.isEmpty()) {
                    const qreal scale=image.devicePixelRatio();
                    shot=image.copy(QRect(qRound(area.x()*scale),qRound(area.y()*scale),
                                          qRound(area.width()*scale),qRound(area.height()*scale)));
                }
                require(shot.save(output+"/"+name+".png"),"cannot save documentation screenshot");
            };
            findItem("capacityInput")->setProperty("text","200");
            findItem("freeInput")->setProperty("text","50");
            findItem("backpackInput")->setProperty("text","200");
            findItem("columnsSlider")->setProperty("value",20);
            findItem("widthSlider")->setProperty("value",1678);
            QMetaObject::invokeMethod(window,"applyEdgeFit",Q_ARG(QVariant,0));
            preview->setProperty("physicalEnabled",true);
            preview->setProperty("perkEnabled",true);
            preview->setProperty("perkLevel",3);
            preview->setProperty("backpackType",2);
            preview->setProperty("backpackQuality",5);
            preview->setProperty("gameMode",false);
            capture("main");
            const int mainColumns=findItem("columnsSlider")->property("value").toInt();
            findItem("widthSlider")->setProperty("value",603);
            capture("layout-vanilla-width");
            findItem("widthSlider")->setProperty("value",1678);
            capture("layout-widest");
            require(findItem("columnsSlider")->property("value").toInt()==mainColumns,
                    "width-only comparison changed column count");
            const QRectF previewArea=bounds(preview->parentItem()).adjusted(-1,-1,1,1);
            capture("preview-mode",previewArea);
            preview->setProperty("gameMode",true);
            capture("game-mode",previewArea);
            preview->setProperty("gameMode",false);
            findItem("capacityInput")->setProperty("text","48");
            findItem("freeInput")->setProperty("text","32");
            findItem("backpackInput")->setProperty("text","48");
            preview->setProperty("physicalEnabled",false);
            preview->setProperty("perkEnabled",false);
            findItem("columnsSlider")->setProperty("value",8);
            findItem("widthSlider")->setProperty("value",603);
            QTest::qWait(300);
            capture("defaults");
            // Capture the actual controls, including labels, at their rendered positions.
            const QRectF settingsArea=bounds(findItem("capacityInput")->parentItem()->parentItem())
                    .united(bounds(findItem("detailsButton"))).adjusted(-10,-10,10,10);
            capture("settings",settingsArea);
            const QRectF gameArea=bounds(findItem("gameCombo"))
                    .united(bounds(findItem("installButton"))).adjusted(-10,-10,10,10);
            capture("installation",gameArea);
            auto *details=window->findChild<QObject *>("detailsDialog");
            require(details,"details dialog missing");
            QMetaObject::invokeMethod(details,"open");
            QTest::qWait(350);
            capture("details",popupBounds(details).adjusted(-8,-8,8,8));
            auto *detailsContent=details->property("contentItem").value<QQuickItem *>();
            detailsContent->setProperty("contentY",qMax(0.0,detailsContent->property("contentHeight").toReal()-detailsContent->height()));
            capture("backpack-details",popupBounds(details).adjusted(-8,-8,8,8));
            QMetaObject::invokeMethod(details,"close"); QTest::qWait(250);
            QMetaObject::invokeMethod(findItem("installButton"),"clicked");
            QTest::qWait(350);
            auto *notice=window->findChild<QObject *>("noticeDialog");
            require(notice,"install notice missing");
            capture("install-confirmation",popupBounds(notice).adjusted(-8,-8,8,8));
            QMetaObject::invokeMethod(findItem("noticeConfirmButton"),"clicked"); QTest::qWait(250);
        }
        require(warnings==0,"QML warnings while generating documentation screenshots");
        qInfo()<<"README screenshots generated in Chinese and English";
        return 0;
    }
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
