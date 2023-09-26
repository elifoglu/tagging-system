import './style.css';
//import './style_dark.css'; -- add this line to enable dark mode
import {Elm} from './Main.elm';

let obj = {

};

let elm = Elm.Main.init({
    node: document.getElementById('root'),
    flags: obj
});

elm.ports.title.subscribe(title => {
    document.title = title;
});


// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
