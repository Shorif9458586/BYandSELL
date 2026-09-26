import type {Config} from "tailwindcss";
const config:Config={content:["./app/**/*.{ts,tsx}","./components/**/*.{ts,tsx}"],theme:{extend:{colors:{brand:"#0f766e",ink:"#102a43"}}},plugins:[]};
export default config;