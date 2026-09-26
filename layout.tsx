import "./globals.css";
import type {Metadata} from "next";
export const metadata:Metadata={
 title:"E-Vumi Seba | জমি সংক্রান্ত সেবায় সহায়তা",
 description:"জমি সংক্রান্ত সেবা সহায়তার জন্য Bangla-first private service platform."
};
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="bn"><body>{children}</body></html>}