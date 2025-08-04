public with sharing class PDFRestDTO {
    public class PDFWithAddedTextFieldData {
        public String font = 'Times New Roman';
        public String opacity = '1';
        public String rotation = '0';
        public String text_color_rgb = '0,0,0';
        public String text_size = '16';

        public String text;
        public String max_width;
        public String page;
        public String x;
        public String y;
    }

    public class PDFWithAddedTextResponse {
        public String outputUrl;
        public String outputId;
        public String inputId;
        public String message;
        public String sfWorkFileId;
        public String sfFileName;
        public String sfFileId;
    }

    public class FileUploadRequest {

    }

    public class FileWrapper {
        public String fileName;
        public Blob fileBlob;
        public Id fileId;
        public String contentType = 'application/pdf';
        public Map<String, String> fields;
        public FileWrapper() {}
     }
}