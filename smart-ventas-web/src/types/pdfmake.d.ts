declare module 'pdfmake' {
  interface FontDescriptors {
    [name: string]: {
      normal: Buffer;
      bold?: Buffer;
      italics?: Buffer;
      bolditalics?: Buffer;
    };
  }

  class PdfPrinter {
    constructor(fonts: FontDescriptors);
    createPdfKitDocument(docDefinition: object): import('stream').PassThrough;
  }

  export = PdfPrinter;
}
