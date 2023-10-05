import './style.css';
import './theme-light.css';
import './theme-dark.css';

import {Elm} from './Main.elm';

var activeTheme = localStorage.getItem('ts-activeTheme');
var tagTextViewType = localStorage.getItem('ts-tagTextViewType');

let obj = {
    activeTheme: activeTheme,
    tagTextViewType: tagTextViewType
};

document.documentElement.setAttribute("data-theme", (activeTheme != null) ? activeTheme : "light");

let elm = Elm.Main.init({
    node: document.getElementById('root'),
    flags: obj
});

elm.ports.storeTheme.subscribe(activeTheme => {
    localStorage.setItem('ts-activeTheme', activeTheme);
    document.documentElement.setAttribute("data-theme", activeTheme)
});

elm.ports.storeTagTextViewType.subscribe(tagTextViewTypeValue => {
    localStorage.setItem('ts-tagTextViewType', tagTextViewTypeValue);
});

elm.ports.title.subscribe(title => {
    document.title = title;
});

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
