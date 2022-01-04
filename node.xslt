<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="text"/>

  <xsl:variable name="newline">
<xsl:text>
</xsl:text>
  </xsl:variable>

  <xsl:key name="elements" match="*" use="name()"/>

  <xsl:template match="/">
    <xsl:for-each 
      select="//*[generate-id(.)=generate-id(key('elements',name())[1])]">
      <xsl:sort select="name()"/>
      <xsl:for-each select="key('elements', name())">
        <xsl:if test="position()=1">
          <xsl:value-of select="name()"/>
          <xsl:text> : </xsl:text>
          <xsl:value-of select="count(//*[name()=name(current())])"/>
          <xsl:value-of select="$newline"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:for-each>
    <xsl:value-of select="$newline"/>
  </xsl:template>
    
</xsl:stylesheet>
