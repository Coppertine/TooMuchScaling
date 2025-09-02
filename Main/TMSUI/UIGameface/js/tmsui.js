import * as DataStore from '/js/common/core/DataStore.js';
import * as Engine from '/js/common/core/Engine.js';
import * as Input from '/js/common/core/Input.js';
import * as Localisation from '/js/common/core/Localisation.js';
import * as Player from '/js/common/core/Player.js';
import * as System from '/js/common/core/System.js';
import { loadDebugDefaultTools } from '/js/common/debug/DebugToolImports.js';
import * as preact from '/js/common/lib/preact.js';
import { loadCSS } from '/js/common/util/CSSUtil.js';
import * as Format from '/js/common/util/LocalisationUtil.js';
import * as FontConfig from '/js/config/FontConfig.js';
import {translate} from '/js/common/core/Localisation.js'
import { Button } from '/js/project/components/Button.js';
import { ManagementMenuButton } from '/js/project/modules/managementMenu/ManagementMenuButton.js';
import { classNames } from '/js/common/lib/classnames.js';
FontConfig;
Engine.initialiseSystems([
    { system: Engine.Systems.System, initialiser: System.attachToEngineReadyForSystem },
    { system: Engine.Systems.DataStore, initialiser: DataStore.attachToEngineReadyForSystem },
    { system: Engine.Systems.Input, initialiser: Input.attachToEngineReadyForSystem },
    { system: Engine.Systems.Localisation, initialiser: Localisation.attachToEngineReadyForSystem },
    { system: Engine.Systems.Player, initialiser: Player.attachToEngineReadyForSystem },
]);
let _minScale = 0.1;
let _maxScale = 50;
Engine.whenReady.then(async () => {
    await loadCSS('project/Shared');
    await loadDebugDefaultTools();
   
    preact.render(preact.h(TMSOverlay, null), document.body);
    Engine.sendEvent('OnReady');
}).catch(Engine.defaultCatch);
class TMSOverlay extends preact.Component {
    static defaultProps = {
        moduleName: 'TMSUI',
    };
    state = {
        visible: false,
	minScale: 0.1,
	maxScale: 50
    };
    componentWillMount() {
        Engine.addListener('Show', this.onShow);
        Engine.addListener('Hide', this.onHide);
    }
    componentWillUnmount() {
        Engine.removeListener('Show', this.onShow);
        Engine.removeListener('Hide', this.onHide);
    }
    render(props, state) {

	if(!this.state.visible)
	{
            return preact.h("div", {className:'TMSUI_root'});
	}
        return (preact.h("div", {className:'TMSUI_root'},
            preact.h("div", { className: 'TMSUI_overlay' },
                preact.h("span", null, translate(`[TMSOriginalScale:MinScale=|${state.minScale * 100}|:MaxScale=|${state.maxScale * 100}|]`)),
               // preact.h("span", null, translate(`[TMSOriginalScale:MinScale=|1|:MaxScale=|500|]`)),
            )
        ))
    }

    onShow = (data) => {
	let {minscale, maxscale} = data;
        this.setState({ visible: true, minScale: minscale, maxScale: maxscale });
    };
    onHide = () => {
        this.setState({ visible: false });
    };
}
