import './style.css';
//import './style_dark.css';

import {Elm} from './Main.elm';

var tagTextViewType = localStorage.getItem('ts-tagTextViewType');

let obj = {
    tagTextViewType: tagTextViewType
};

let elm = Elm.Main.init({
    node: document.getElementById('root'),
    flags: obj
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
