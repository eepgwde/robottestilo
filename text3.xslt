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

<xsl:apply-templates select="node()|@*"/>
<xsl:apply-templates select="node()|@*"/>

<xsl:template match="node()|@*">
<xsl:apply-templates select="node()|@*"/>
</xsl:template>

  -->

  <xsl:template match="node()|@*">
    <xsl:apply-templates select="node()|@*"/>
  </xsl:template>

  <xsl:template match="*/*[@clickable = 'true']">
    <xsl:if test="@clickable = 'true'">
      <xsl:text>-- &#10;&#10;</xsl:text>
      <xsl:text>clk.text.</xsl:text>
      <xsl:value-of select="position()"/>
      <xsl:text>=</xsl:text>
      <xsl:value-of select="substring(@text,1,80)"/>
      <xsl:text>&#10;</xsl:text>

      <xsl:text>clk.path.</xsl:text>
      <xsl:value-of select="position()"/>
      <xsl:text>=</xsl:text>
      <xsl:value-of select="path()"/>
      <xsl:text>&#10;</xsl:text>

      <xsl:text>clk.class.</xsl:text>
      <xsl:value-of select="position()"/>
      <xsl:text>=</xsl:text>
      <xsl:value-of select="@class"/>
      <xsl:text>|</xsl:text>
      <xsl:value-of select="local-name()"/>
      <xsl:text>&#10;</xsl:text>

      <xsl:for-each select="./*[@text != '']">
	<xsl:text>txt.text.</xsl:text>
	<xsl:value-of select="position()"/>
	<xsl:text>=</xsl:text>
	<xsl:value-of select="substring(@text,1,80)"/>
	<xsl:text>&#10;</xsl:text>
	<xsl:text>txt.path.</xsl:text>
	<xsl:value-of select="position()"/>
	<xsl:text>=</xsl:text>
	<xsl:value-of select="path()"/>
	<xsl:text>&#10;</xsl:text>

	<xsl:text>txt.class.</xsl:text>
	<xsl:value-of select="position()"/>
	<xsl:text>=</xsl:text>
	<xsl:value-of select="local-name()"/>
	<xsl:text>&#10;</xsl:text>
      </xsl:for-each>
    </xsl:if>
  </xsl:template>
  
</xsl:stylesheet>
