<script lang="ts">
	import ArchivePage from '../../+page.svelte';
	// This route re-exports the root load and actions, whose types SvelteKit
	// does not infer through a re-export.
	import type { ActionData, PageData } from '../../$types';

	let { data, form }: { data: PageData; form: ActionData } = $props();
</script>

<ArchivePage {data} {form} />
