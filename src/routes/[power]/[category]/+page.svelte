<script lang="ts">
	import ArchivePage from '../../+page.svelte';

	let { data, form }: { data: any; form: any } = $props();
</script>

<ArchivePage {data} {form} />
