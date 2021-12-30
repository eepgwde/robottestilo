<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:math="http://www.exslt.org/math" exclude-result-prefixes="math">


  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes" omit-xml-declaration="yes"/>

  <!-- 
       weaves

       This processes Appium W3C captured pages.
       (Currently, only Android App XML pages.)

       It looks for any clickable elements and then finds the text elements below it.
       It records the XPath, it uses path() from XSLT version 2.0 so you will need
       Saxon. 

       Attributes transferred are text, content-desc and bounds. The bounds gives you a 
       clue where the clickable element lies. They are in top to bottom order.

  -->

  <!--

<xsl:template match="node()|@*">

<xsl:apply-templates select="node()|@*"/>

  -->

  <xsl:template match="node()|@*">
    <xsl:apply-templates select="node()|@*"/>
  </xsl:template>

  <xsl:template match="*/*[@clickable = 'true']">
    <xsl:if test="@clickable = 'true'">
      <xsl:text># clickable&#10;</xsl:text>

      <xsl:variable name="id0" select="generate-id()" /> 
      <xsl:variable name="id1" select="position()" /> 
      
      <xsl:text>clk.text.</xsl:text>
      <xsl:value-of select="$id0"/>
      <xsl:text>.</xsl:text>
      <xsl:value-of select="$id1"/>
      <xsl:text>=</xsl:text>
      <xsl:value-of select="substring(@text,1,80)"/>
      <xsl:text>&#10;</xsl:text>

      <xsl:text>clk.desc.</xsl:text>
      <xsl:value-of select="$id0"/>
      <xsl:text>.</xsl:text>
      <xsl:value-of select="$id1"/>
      <xsl:text>=</xsl:text>
      <xsl:value-of select="substring(@content-desc,1,80)"/>
      <xsl:text>&#10;</xsl:text>

      <xsl:text>clk.cls.</xsl:text>
      <xsl:value-of select="$id0"/>
      <xsl:text>.</xsl:text>
      <xsl:value-of select="$id1"/>
      <xsl:text>=</xsl:text>
      <xsl:value-of select="local-name()"/>
      <xsl:text>&#10;</xsl:text>

      <xsl:text>clk.bounds.</xsl:text>
      <xsl:value-of select="$id0"/>
      <xsl:text>.</xsl:text>
      <xsl:value-of select="$id1"/>
      <xsl:text>=</xsl:text>
      <xsl:value-of select="@bounds"/>
      <xsl:text>&#10;</xsl:text>

      <xsl:text>clk.path.</xsl:text>
      <xsl:value-of select="$id0"/>
      <xsl:text>.</xsl:text>
      <xsl:value-of select="$id1"/>
      <xsl:text>=</xsl:text>
      <xsl:value-of select="replace(path(), '(Q\{\})', '')"/>
      <xsl:text>&#10;</xsl:text>

      <xsl:for-each select="./*[(@text != '') or (@content-desc != '')]">

	<xsl:text>## clickable text&#10;</xsl:text>
	<xsl:text>txt.text.</xsl:text>
	<xsl:value-of select="$id0"/>
	<xsl:text>.</xsl:text>
	<xsl:value-of select="$id1"/>
	<xsl:text>.</xsl:text>
	<xsl:value-of select="position()"/>
	<xsl:text>=</xsl:text>
	<xsl:value-of select="substring(@text,1,80)"/>
	<xsl:text>&#10;</xsl:text>

	<xsl:text>txt.desc.</xsl:text>
	<xsl:value-of select="$id0"/>
	<xsl:text>.</xsl:text>
	<xsl:value-of select="$id1"/>
	<xsl:text>.</xsl:text>
	<xsl:value-of select="position()"/>
	<xsl:text>=</xsl:text>
	<xsl:value-of select="substring(@content-desc,1,80)"/>
	<xsl:text>&#10;</xsl:text>

	<xsl:text>txt.cls.</xsl:text>
	<xsl:value-of select="$id0"/>
	<xsl:text>.</xsl:text>
	<xsl:value-of select="$id1"/>
	<xsl:text>.</xsl:text>
	<xsl:value-of select="position()"/>
	<xsl:text>=</xsl:text>
	<xsl:value-of select="local-name()"/>
	<xsl:text>&#10;</xsl:text>

	<xsl:text>txt.bounds.</xsl:text>
	<xsl:value-of select="$id0"/>
	<xsl:text>.</xsl:text>
	<xsl:value-of select="$id1"/>
	<xsl:text>=</xsl:text>
	<xsl:value-of select="position()"/>
	<xsl:text>=</xsl:text>
	<xsl:value-of select="@bounds"/>
	<xsl:text>&#10;</xsl:text>

	<xsl:text>txt.path.</xsl:text>
	<xsl:value-of select="$id0"/>
	<xsl:text>.</xsl:text>
	<xsl:value-of select="$id1"/>
	<xsl:text>.</xsl:text>
	<xsl:value-of select="position()"/>
	<xsl:text>=</xsl:text>
	<xsl:value-of select="replace(path(), '(Q\{\})', '')"/>
	<xsl:text>&#10;</xsl:text>

      </xsl:for-each>
    </xsl:if>
  </xsl:template>
  
</xsl:stylesheet>
