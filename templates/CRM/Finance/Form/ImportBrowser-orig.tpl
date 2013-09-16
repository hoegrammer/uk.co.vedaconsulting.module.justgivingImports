<table><tr><td>
    <div style="float: left; margin: 5px;">
        <table style="width: 300px">
          <thead><tr><td colspan="2"><b>Filter</b></td></tr></thead>
          <tbody>
               <tr><td>{$form.status.label}</td><td>{$form.status.html}</td></tr>
          </tbody>
        </table>
        <div class="crm-submit-buttons">{include file="CRM/common/formButtons.tpl"}</div>
    </div>
    <div style="float: left;  margin: 5px;">{include file="CRM/Finance/Form/Import/importSummary.tpl"}</div>
    <div style="float: left;  margin: 5px;">{include file="CRM/Finance/Form/Import/validationSummary.tpl" readonly="1" nobrowserlink="1"}</div>
</td></tr>
</table>

{include file="CRM/common/pager.tpl" location="top"}
{include file="CRM/common/pagerAToZ.tpl"}

{include file="CRM/common/enableDisable.tpl"}         
{include file="CRM/common/jsortable.tpl"}
{assign var=columnCount value=$columnHeaders|@count}
<table>
<thead>
    <th>Act.</th>
    {foreach from=$columnHeaders item=header}
        <th scope="col">
        {if $header.sort}
          {assign var='key' value=$header.sort}
          {$sort->_response.$key.link}
        {else}
          {$header.name}
        {/if}
        </th>
     {/foreach}
</thead>
<tbody>
{foreach from=$rows item=row}
    <tr id='rec_{$row.id}' data-id="{$row.id}" data-contact-search="{$row.search_contact_name}" class="{cycle values="odd-row,even-row"}">
        <td>{if $row.error_status && !$readonly}<a href="#" class="fix_link">Edit</a>{/if}</td>
        {foreach from=$columnHeaders item=header}
            <td class="rec_value {$header.name}">{$row[$header.name]}</td>
        {/foreach}
    </tr>
{/foreach}
</tbody>
</table>

<div id="editor-template" style="display:none">
<table>
    <tr>
    <td>
       {assign var="blockNo" value="1"}
       {include file="CRM/Contact/Form/NewContact.tpl"}
     </td>
     </tr>
<tr><td>Contact name</td><td><input name="contact_name" type="text" data-contact-search="display_name" size="50" /></td></tr>
<tr><td>Postcode</td><td><input name="contact_postcode" type="text" data-contact-search="postal_code" size="20" /></td></tr>
<tr><td>VA Number</td><td><input name="contact_va" type="text" data-contact-search="external_identifier" size="20" /></td></tr>
<tr><td>Reference</td><td><input name="transfer_reference" type="text" data-contact-search="custom_134" size="20" /></td></tr>
</table>
<input type="button" id="editor-search" value="Search" />
<input type="button" id="editor-update" value="Update" />
<input type="button" id="editor-cancel" value="Cancel" />
<table class="results">
</table>
</div>

<script type="text/javascript">
// Stop here
// var contactIndividualUrl = "{crmURL p='civicrm/ajax/rest' q='json=1&sequential=1&debug=1&&entity=Contact&action=get&return[display_name]=1&return[sort_name]=1&return[email]=1&return[street_address]=1&return[city]=1&return[postal_code]=1&return[tags]=1' h=0}";
//var contactIndividualUrl = "{crmURL p='civicrm/contact/search' q='json=1&return[display_name]&return[sort_name]=1&return[email]=1&return[street_address]=1&return[city]=1&return[postal_code]=1&return[tags]=1' h=0}";
var contactIndividualUrl = "{crmURL p='civicrm/ajax/rest' q='fnName=civicrm/contact/search&json=1&return[display_name]&return[sort_name]=1&return[email]=1&return[street_address]=1&return[city]=1&return[postal_code]=1&return[tags]=1' h=0}";
var viewIndividual = "{crmURL p='civicrm/contact/view' q='reset=1&cid=' h=0}";
var ajaxUpdateImport = "{crmURL p='civicrm/finance/ajax/updateimport' q="import_id=$importId" h=0}";
var editingTr = null;
{literal}
cj(function( ) {
    var renderTable = function() {
        var params = {};
        cj("#editor-row input[data-contact-search]").each(function(i, inputEl) {
            var name = cj(inputEl).attr('data-contact-search');
            alert("Name="+name);
            var val = cj(inputEl).val();
            alert("val="+val);
            if(val) {
                params[name] = val;
                alert("params[name]="+params[name]);
            }
        });

        cj("#editor-row .results").html("<tr><td>Loading contacts ...</td></tr>");
            
        cj.getJSON(contactIndividualUrl, params, function(data) {
        alert("params="+params);
            var msg = "";
            var rendered = 0;
            cj.each(data.values, function(i, rec) {
                if(i == 'deprecated' || i == 'is_error') {
                    return;
                }

                rendered++;
                msg += "<tr><td><input type=\"radio\" name=\"contact_id\" value=\"" + rec.contact_id + "\"></td>" + 
                    "<td><a href=\"" + viewIndividual + rec.contact_id + "\" target=\"individual\">" + rec.display_name + "</a></td>" +
                    "<td>" +  rec.street_address + ", " + rec.city + ", "  + rec.postal_code + "</td>" +
                    "<td>" + rec.tags + "</td></tr>";
            });

            if(rendered == 0) {
                msg += "<tr><td>No contacts found!</td></tr>";
            }
            cj("#editor-row .results").html(msg);
            cj("#editor-row input[type=radio]").click(function(event) {
                console.log(cj(event.target).val());
            });
        });
    }

    cj('.fix_link').click(function(event) {
        if(editingTr != null) {
            editingTr.toggleClass('highlight');
            alert("You're editing another line already");
            return false;
        }

        editingTr = cj(cj(event.target).parent().parent());
        var templateEl = cj("#editor-template");
        editingTr.after("<tr id=\"editor-row\"><td colspan=\"20\">" + templateEl.html() + "</td></tr>");
        
        var id = editingTr.attr('data-id');

        cj("#editor-row #editor-cancel").click(function(event) {
            cj("#editor-row").remove();
            editingTr = null;
        });

        cj("#editor-row #editor-search").click(function(event) {
            renderTable();
        });

        cj("#editor-row #editor-update").click(function(event) {
            var contactId = cj("input[name=contact_id]:checked").val();
            if(contactId == undefined) {
                return false;
            }

            cj("#editor-row input[type=button]").attr('disabled','disabled').addClass('ui-state-disabled');
            cj("#editor-row #editor-update").val("Updating ...");
            cj.getJSON(ajaxUpdateImport, {id: editingTr.attr('data-id'), contact_id: contactId}, function(response) {
                cj.each(response.data, function(i, dat) {
                    editingTr.children('td.rec_value.' + i).html(dat);
                });

                cj("#editor-row").remove();
                editingTr = null;
            });

            return false;
        });

        cj("#editor-row input[type=text]").keypress(function(e){
            //prevent 'enter' key from submitting the form
            if(e.which == 13){
                renderTable();
                
                e.preventDefault();
                return false;
            }
        });
        
        //autoload options
        var searchStr = editingTr.attr('data-contact-search');
        if(searchStr) {
            cj("#editor-row input[name=contact_name]").val(searchStr);
            renderTable();
        }
        
        return false;
    });
});

{/literal}
</script>

{include file="CRM/common/pager.tpl" location="bottom"}
