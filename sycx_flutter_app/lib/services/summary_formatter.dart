import 'package:html/dom.dart' as html_dom;

class SummaryFormatter {
  static Future<String> formatSummary(String summaryContent) async {
    try {
      // Split the summary into sentences
      List<String> sentences = summaryContent.split('.');

      // Create the formatted HTML structure
      final formattedDocument = html_dom.Document();
      final body = formattedDocument.createElement('body');
      formattedDocument.append(body);

      // Variable to track table and list for scoping
      html_dom.Element? table;
      html_dom.Element? list;

      // Iterate through the sentences and apply formatting
      for (int i = 0; i < sentences.length; i++) {
        final paragraph = formattedDocument.createElement('p');
        paragraph.text = '${sentences[i]}.';
        paragraph.attributes['style'] =
            'font-family: "Architects Daughter", cursive; font-size: 16px; line-height: 1.5; margin-bottom: 12px;';
        body.append(paragraph);

        // Add visual enhancements based on the length of the summary
        if (sentences.length > 5) {
          // Add a table for key points
          if (i == 0) {
            table = formattedDocument.createElement('table');
            table.attributes['style'] =
                'width: 100%; border-collapse: collapse; margin-top: 24px;';
            final tableHeader = formattedDocument.createElement('tr');
            tableHeader.children.add(
                formattedDocument.createElement('th')..text = 'Key Points');
            tableHeader.children
                .add(formattedDocument.createElement('th')..text = 'Details');
            table.children.add(tableHeader);
            body.children.add(table);
          }

          // Add a row to the table
          if (table != null) {
            final tableRow = formattedDocument.createElement('tr');
            final keyPointCell = formattedDocument.createElement('td');
            keyPointCell.text = 'Point ${i + 1}';
            keyPointCell.attributes['style'] =
                'font-weight: bold; padding: 8px;';
            final detailCell = formattedDocument.createElement('td');
            detailCell.text = sentences[i];
            detailCell.attributes['style'] = 'padding: 8px;';
            tableRow.children.add(keyPointCell);
            tableRow.children.add(detailCell);
            table.children.add(tableRow);
          }
        } else if (sentences.length > 3) {
          // Add a bulleted list for the summary
          if (i == 0) {
            list = formattedDocument.createElement('ul');
            list.attributes['style'] =
                'list-style-type: disc; margin-top: 24px; padding-left: 20px;';
            body.children.add(list);
          }

          // Add list item if list exists
          if (list != null) {
            final listItem = formattedDocument.createElement('li');
            listItem.text = sentences[i];
            list.children.add(listItem);
          }
        }
      }

      // Convert the formatted HTML document to a string
      return formattedDocument.outerHtml;
    } catch (e) {
      print('Error formatting summary: $e');
      return summaryContent;
    }
  }
}
