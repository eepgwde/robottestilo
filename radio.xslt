<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:math="http://www.exslt.org/math" exclude-result-prefixes="math">


  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes" omit-xml-declaration="yes"/>

  <!-- In the document "prices.xml", find the minimum price for each book, in the form of a "minprice" element with the book title as its title attribute. -->

  <!--
      <results>
      {
      let $doc := document("prices.xml")
      for $t in distinct-values($doc//book/title)
      let $p := $doc//book[title = $t]/price
      return
      <minprice title={ $t/text() }>
      <price>{ min(decimal($p/text())) }</price>
      </minprice>
      }
      </results>
  -->

  <xsl:template match="/">
    <xsl:for-each select="/hierarchy//*/android.widget.RadioButton">
      <xsl:if test="@checkable = 'true' and @clickable = 'true'">
        <xsl:value-of select="./@resource-id"/>
        <xsl:text>&#10;</xsl:text>
        <xsl:value-of select="./@text"/>
        <xsl:text>&#10;</xsl:text>
      </xsl:if>
      </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
