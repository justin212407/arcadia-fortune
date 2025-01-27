import type { Metadata } from "next";
import { PropsWithChildren } from "react";

export const metadata: Metadata = {
  title: "Create New fortune(prize)",
  description: "Create new fortune(prize)",
};

const Createfortune(prize)Layout = ({ children }: PropsWithChildren) => {
  return <div>{children}</div>;
};

export default Createfortune(prize)Layout;
