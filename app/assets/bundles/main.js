/* eslint-disable import/first */

/* Polyfills */
import 'whatwg-fetch';
import 'core-js/features/promise';

/* Polyfills for Stimulus */
import 'core-js/features/array';
import 'core-js/features/map';
import 'core-js/features/object/assign';
import 'core-js/features/set';
import 'element-closest';
import 'mutation-observer-inner-html-shim';
import 'eventlistener-polyfill';

/* Rails UJS */
import Rails from '@rails/ujs';

Rails.start();

/* Stimulus */
import { Application } from 'stimulus';
import { definitionsFromContext } from 'stimulus/webpack-helpers';

const application = Application.start();
application.load(definitionsFromContext(
  require.context('../shared/controllers', true, /\.js$/)
));
application.load(definitionsFromContext(
  require.context('../main/controllers', true, /\.js$/)
));

/* Font Awesome */
import '@fortawesome/fontawesome-free/scss/fontawesome.scss';
import '@fortawesome/fontawesome-free/scss/solid.scss';
import '@fortawesome/fontawesome-free/scss/regular.scss';
import '@fortawesome/fontawesome-free/scss/brands.scss';

/* Styling */
import '../main/index.scss';
