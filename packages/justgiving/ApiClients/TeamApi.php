<?php
include_once 'ClientBase.php';
include_once 'Http/CurlWrapper.php';

class TeamApi extends ClientBase
{		

    public function Create(Team $team)
	{
		$locationFormat = $this->Parent->RootDomain . "{apiKey}/v{apiVersion}/team/" + $team->teamShortName;
		$url = $this->BuildUrl($locationFormat);
		$payload = json_encode($team);
		$json = $this->curlWrapper->Put($url, $this->BuildAuthenticationValue(), $payload);
		return json_decode($json);
	}
}
