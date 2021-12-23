<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:math="http://www.exslt.org/math" exclude-result-prefixes="math">

  <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="no" omit-xml-declaration="yes"/>

  <xsl:template match="node()|@*">
    <xsl:apply-templates select="node()|@*"/>
  </xsl:template>

  <xsl:template match="android.widget.EditText">
    <xsl:if test="@clickable = 'true'">
      <xsl:text>page.etext.resource-id=</xsl:text>

      <xsl:value-of select="substring(./@resource-id,1,80)"/>
      <xsl:text>|</xsl:text>

      <xsl:value-of select="./@bounds"/>
      <!-- to represent blank text and make the records the same -->
      <xsl:text>|</xsl:text>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="android.widget.TextView">
    <!-- Textview does not have editted text -->
    <xsl:if test="@text != ''">
      <xsl:text>page.textv.resource-id=</xsl:text>

      <xsl:value-of select="substring(./@resource-id,1,80)"/>
      <xsl:text>|</xsl:text>

      <xsl:value-of select="./@bounds"/>
      <xsl:text>|</xsl:text>

      <xsl:value-of select="substring(@text,1,80)"/>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="android.widget.RadioButton">
    <xsl:if test="@checkable = 'true' and @clickable = 'true'">
      <xsl:text>page.textv.resource-id=</xsl:text>

      <xsl:value-of select="substring(./@resource-id,1,80)"/>
      <xsl:text>|</xsl:text>

      <xsl:value-of select="./@bounds"/>
      <xsl:text>|</xsl:text>

      <xsl:value-of select="substring(@text,1,80)"/>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="android.widget.Button">
    <xsl:if test="@clickable = 'true'">
      <xsl:text>page.bttn.resource-id=</xsl:text>

      <xsl:value-of select="substring(./@resource-id,1,80)"/>
      <xsl:text>|</xsl:text>

      <xsl:value-of select="./@bounds"/>
      <xsl:text>|</xsl:text>

      <xsl:value-of select="substring(@text,1,80)"/>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
